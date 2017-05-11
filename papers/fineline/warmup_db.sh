#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SF=750
THREADS=20
SNAPSHOT=db-$SF-work

declare -A CFG

# CFG["warmup_db-instant"]=" --sm_restart_instant true"
# CFG["warmup_db-pagebased"]=" --sm_restart_instant false --sm_restart_log_based_redo false"
CFG["warmup_db-logbased"]=" --sm_restart_instant false --sm_restart_log_based_redo true"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
queried_sf=$SF
threads=$THREADS
duration=300
asyncCommit=true
sm_bufpoolsize=60000
sm_vol_o_direct=true
sm_log_benchmark_start=true
sm_cleaner_interval=0
sm_cleaner_workspace_size=4096
sm_cleaner_policy=oldest_lsn
sm_cleaner_num_candidates=10240
sm_chkpt_interval=5000
sm_chkpt_log_based=false
sm_bufferpool_swizzle=false
sm_archiving=false
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
    echo -n "Loading snapshot for nodb ... "
    load_snapshot.sh $SNAPSHOT
    [ $? -eq 0 ] || return 1;
    echo "OK"

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

    # zapps xctlatency -l ${MOUNTPOINT[log]}/log > xctlatency.txt
    # zapps tracerestore -l ${MOUNTPOINT[log]}/log > tracerestore.txt
}
