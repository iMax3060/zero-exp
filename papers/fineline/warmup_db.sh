#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SF=750
THREADS=24
SNAPSHOT=db-$SF

declare -A CFG

CFG["warmup_db-instant"]=" --sm_restart_instant true"
# CFG["warmup_db-pagebased"]=" --sm_restart_instant false --sm_restart_log_based_redo false"
# CFG["warmup_db-logbased"]=" --sm_restart_instant false --sm_restart_log_based_redo true"
# CFG["warmup_db-sorted"]=" sm_archiving=true sm_archiver_workspace_size=6400 sm_archiver_bucket_size=1 sm_chkpt_use_log_archive=true"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
queried_sf=$SF
threads=$THREADS
asyncCommit=true
no_stop=true
crashDelay=910
crashDelayAfterInit=false
skew=false
skewShiftDelay=0
sm_bufpoolsize=300000
sm_vol_o_direct=true
sm_log_benchmark_start=true
sm_cleaner_interval=0
sm_cleaner_workspace_size=4096
sm_cleaner_policy=oldest_lsn
sm_cleaner_num_candidates=10240
sm_chkpt_interval=5000
sm_chkpt_log_based=false
sm_bufferpool_swizzle=false
sm_shutdown_clean=false
sm_truncate_log=false
sm_vol_cluster_stores=true
sm_page_img_compression=16384
sm_log_o_direct=false
sm_log_delete_old_partitions=false
EOF

# warmup=true
# crashDelay=20

function startTrimLoop()
{
    sudo /sbin/sysctl vm.drop_caches=3
    while true; do
        sleep 60;
        # sudo -n fstrim ${MOUNTPOINT[log]};
        # sudo -n fstrim ${MOUNTPOINT[archive]};
    done
}

function beforeHook()
{
    local snap=$SNAPSHOT
    local iter=${1:-0}
    iter=5
    if [ $iter -gt 0 ]; then
        local lv=$((1 << (iter-1)))
        snap=$SNAPSHOT-$lv
    fi
    echo "Loading snapshot $snap"
    load_snapshot.sh $snap
    [ $? -eq 0 ] || return 1;

    startTrimLoop &
    TRIMPID=$!
}

function afterHook()
{
    kill -9 $TRIMPID > /dev/null 2>&1
    zapps agglog -l ${MOUNTPOINT[log]}/log \
        -b benchmark_start \
        -t xct_end \
        > agglog.txt

    zapps xctlatency -b benchmark_start -l ${MOUNTPOINT[log]}/log > xctlatency.txt
    # zapps tracerestore -l ${MOUNTPOINT[log]}/log > tracerestore.txt
}
