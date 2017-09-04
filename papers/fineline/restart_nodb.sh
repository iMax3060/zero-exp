#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SF=75
THREADS=8
SNAPSHOT=nodb-"$SF"

declare -A CFG

CFG["warmup_nodb-1"]=" --sm_batch_segment_size=1"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
queried_sf=$SF
threads=$THREADS
duration=120
asyncCommit=true
no_stop=true
crashDelay=120
sm_log_benchmark_start=false
sm_chkpt_interval=5000
sm_chkpt_log_based=false
sm_log_delete_old_partitions=false
sm_bufferpool_swizzle=false
sm_shutdown_clean=false
sm_truncate_log=false
sm_archiving=true
sm_archiver_eager=true
sm_archiver_bucket_size=1
sm_archiver_workspace_size=130
sm_archiver_merging=true
sm_archiver_fanin=7
sm_no_db=true
sm_bufpoolsize=40000
sm_vol_cluster_stores=true
sm_page_img_compression=16384
EOF

function startTrimLoop()
{
    sudo /sbin/sysctl vm.drop_caches=3
    while true; do
        sudo -n fstrim ${MOUNTPOINT[log]};
        sudo -n fstrim ${MOUNTPOINT[archive]};
        sleep 60;
    done
}

function beforeHook()
{
    echo -n "Loading snapshot for nodb ... "
    load_snapshot.sh $SNAPSHOT
    [ $? -eq 0 ] || return 1;
    echo "OK"

    sudo /sbin/sysctl vm.drop_caches=3

    # startTrimLoop &
    # TRIMPID=$!
}

function afterHook()
{
    # echo
    # kill -9 $TRIMPID > /dev/null 2>&1
    zapps agglog -l ${MOUNTPOINT[log]}/log \
        -t xct_end \
        -b benchmark_start \
        > agglog.txt

    # zapps xctlatency -l ${MOUNTPOINT[log]}/log > xctlatency.txt
    # zapps tracerestore -l ${MOUNTPOINT[log]}/log > tracerestore.txt
}
