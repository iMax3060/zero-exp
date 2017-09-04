#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SF=75
THREADS=8
SNAPSHOT=restore-$SF-work

declare -A CFG

# CFG["restore-5000"]=" --sm_bufpoolsize=10000"
# CFG["restore-10000"]=" --sm_bufpoolsize=10000"
# CFG["restore-15000"]=" --sm_bufpoolsize=10000"
# CFG["restore-20000"]=" --sm_bufpoolsize=10000"
# CFG["restore-25000"]=" --sm_bufpoolsize=25000"
# CFG["restore-30000"]=" --sm_bufpoolsize=30000"
# CFG["restore-35000"]=" --sm_bufpoolsize=35000"
# CFG["restore-40000"]=" --sm_bufpoolsize=40000"
# CFG["restore-45000"]=" --sm_bufpoolsize=45000"
# CFG["restore-50000"]=" --sm_bufpoolsize=50000"
# CFG["restore-60000"]=" --sm_bufpoolsize=60000"
# CFG["restore-70000"]=" --sm_bufpoolsize=70000"
# CFG["restore-80000"]=" --sm_bufpoolsize=80000"

# CFG["restore-16"]=" --sm_batch_segment_size=16"
# CFG["restore-64"]=" --sm_batch_segment_size=64"
# CFG["restore-128"]=" --sm_batch_segment_size=128"
# CFG["restore-256"]=" --sm_batch_segment_size=256"
# CFG["restore-512"]=" --sm_batch_segment_size=512"
# CFG["restore-1024"]=" --sm_batch_segment_size=1024"
# CFG["restore-4096"]=" --sm_batch_segment_size=4096"

# CFG["restore-2500"]=" --sm_bufpoolsize=2500"
# CFG["restore-5000"]=" --sm_bufpoolsize=5000"
# CFG["restore-7500"]=" --sm_bufpoolsize=7500"
# CFG["restore-10000"]=" --sm_bufpoolsize=10000"
# CFG["restore-12500"]=" --sm_bufpoolsize=12500"
CFG["restore-15000"]=" --sm_bufpoolsize=15000"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
threads=$THREADS
queried_sf=$SF
duration=300
failDelay=600
asyncCommit=true
sm_restore_instant=true
sm_bufpoolsize=10000
sm_batch_segment_size=128
sm_cleaner_interval=500
sm_cleaner_policy=oldest_lsn
sm_log_benchmark_start=true
sm_vol_cluster_stores=true
sm_evict_dirty_pages=false
sm_evict_random=false
sm_evict_use_clock=true
sm_async_eviction=false
sm_ticker_print_tput=true
sm_log_page_evictions=false
sm_log_page_fetches=false
sm_vol_log_reads=false
sm_chkpt_interval=5000
sm_chkpt_print_propstats=false
sm_log_delete_old_partitions=false
sm_shutdown_clean=false
sm_archiving=true
sm_archiver_eager=true
sm_archiver_workspace_size=130
sm_archiver_bucket_size=1
sm_bufferpool_swizzle=false
EOF

# function startTrimLoop()
# {
#     while true; do
#         sleep 60;
#         sudo -n fstrim ${MOUNTPOINT[log]};
#         sudo -n fstrim ${MOUNTPOINT[archive]};
#     done
# }

function beforeHook()
{
    echo -n "Loading snapshot ... "
    load_snapshot.sh $SNAPSHOT
    [ $? -eq 0 ] || return 1;
    echo "OK"

#     echo -n "Copying backup ... "
#     rsync -a ${MOUNTPOINT[db]}/db ${MOUNTPOINT[backup]}/backup
#     echo "OK"

    echo -n "Adding backup file ... "
    LASTPART=0
    for l in ${MOUNTPOINT[log]}/log/log.*; do
        FNAME=$(basename "$l")
        EXT="${FNAME##*.}"
        if [ $EXT -gt $LASTPART ]; then
            LASTPART=$EXT
        fi
    done

    zapps addbackup -l ${MOUNTPOINT[log]}/log -f ${MOUNTPOINT[backup]}/backup --lsn $LASTPART".0"
    [ $? -eq 0 ] || return 1;
    echo "OK"

    sudo /sbin/sysctl vm.drop_caches=3
    # startTrimLoop &
    # TRIMPID=$!
}

function afterHook()
{
    kill -9 $TRIMPID > /dev/null 2>&1
    zapps agglog -l ${MOUNTPOINT[log]}/log \
        -t xct_end \
        -t restore_begin \
        -t restore_segment \
        -t restore_end \
        -t page_write \
        -t page_read \
        > agglog.txt

    zapps xctlatency -l ${MOUNTPOINT[log]}/log > xctlatency.txt
    zapps tracerestore -l ${MOUNTPOINT[log]}/log > tracerestore.txt
}
