#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SF=750
THREADS=20
VARIANT=compressed2
SNAPSHOT=nodb-"$SF"-bucket1

declare -A CFG

CFG["warmup_nodb-1"]=" --sm_batch_segment_size=1"
# CFG["warmup_nodb-8"]=" --sm_batch_segment_size=8"
# CFG["warmup_nodb-4"]=" --sm_batch_segment_size=4"
# CFG["warmup_nodb-16"]=" --sm_batch_segment_size=16"
# CFG["warmup_nodb-32"]=" --sm_batch_segment_size=32"
# CFG["warmup_nodb-64"]=" --sm_batch_segment_size=64"
# CFG["warmup_nodb-128"]=" --sm_batch_segment_size=128"
# CFG["warmup_nodb-256"]=" --sm_batch_segment_size=256"
# CFG["warmup_nodb-512"]=" --sm_batch_segment_size=512"
# CFG["warmup_nodb-1024"]=" --sm_batch_segment_size=1024"
# CFG["warmup_nodb-4096"]=" --sm_batch_segment_size=4096"
# CFG["warmup_nodb-8192"]=" --sm_batch_segment_size=8192"
# CFG["warmup_nodb-16384"]=" --sm_batch_segment_size=16384"
# CFG["warmup_nodb-32768"]=" --sm_batch_segment_size=32768"
# CFG["warmup_nodb-65536"]=" --sm_batch_segment_size=65536"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
queried_sf=$SF
threads=$THREADS
duration=120
asyncCommit=true
warmup=false
sm_log_benchmark_start=true
sm_chkpt_interval=5000
sm_chkpt_log_based=false
sm_log_delete_old_partitions=false
sm_bufferpool_swizzle=false
sm_shutdown_clean=false
sm_truncate_log=false
sm_archiving=true
sm_archiver_eager=false
sm_archiver_bucket_size=1
sm_archiver_workspace_size=2048
sm_archiver_merging=false
sm_archiver_fanin=7
sm_no_db=true
sm_bufpoolsize=80000
sm_vol_cluster_stores=true
sm_arch_o_direct=false
sm_log_o_direct=false
sm_log_fetch_buf_partitions=4
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

    startTrimLoop &
    TRIMPID=$!
}

function afterHook()
{
    kill -9 $TRIMPID > /dev/null 2>&1
    zapps agglog -l ${MOUNTPOINT[log]}/log \
        -t xct_end \
        -b benchmark_start \
        > agglog.txt

    # zapps xctlatency -l ${MOUNTPOINT[log]}/log > xctlatency.txt
    # zapps tracerestore -l ${MOUNTPOINT[log]}/log > tracerestore.txt
}
