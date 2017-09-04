#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SF=75
THREADS=12

declare -A CFG

# CFG["buffersizes-500"]=" --sm_bufpoolsize=500"
# CFG["buffersizes-1000"]=" --sm_bufpoolsize=1000"
# CFG["buffersizes-1500"]=" --sm_bufpoolsize=1500"
# CFG["buffersizes-2000"]=" --sm_bufpoolsize=2000"
# CFG["buffersizes-4000"]=" --sm_bufpoolsize=4000"
# CFG["buffersizes-50000-oldest"]=" --sm_bufpoolsize=50000 --sm_cleaner_policy=oldest_lsn"
# CFG["buffersizes-50000-highest"]=" --sm_bufpoolsize=50000 --sm_cleaner_policy=highest_refcount"
# CFG["buffersizes-50000-mixed"]=" --sm_bufpoolsize=50000 --sm_cleaner_policy=mixed"
# CFG["buffersizes-50000-lowest"]=" --sm_bufpoolsize=50000 --sm_cleaner_policy=lowest_refcount"
# CFG["buffersizes-8000"]=" --sm_bufpoolsize=8000"
CFG["buffersizes-10000"]=" --sm_bufpoolsize=10000"
# CFG["buffersizes-12000"]=" --sm_bufpoolsize=12000"
# CFG["buffersizes-14000"]=" --sm_bufpoolsize=14000"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
queried_sf=$SF
threads=$THREADS
duration=7200
asyncCommit=true
sm_archiving=false
sm_cleaner_decoupled=false
sm_cleaner_workspace_size=160
sm_batch_segment_size=64
sm_cleaner_interval=250
sm_cleaner_policy=oldest_lsn
sm_evict_dirty_pages=false
sm_evict_random=false
sm_evict_use_clock=true
sm_async_eviction=false
sm_chkpt_print_propstats=true
sm_log_page_evictions=true
sm_ticker_print_tput=true
sm_log_benchmark_start=false
sm_log_delete_old_partitions=false
sm_vol_o_direct=true
sm_vol_cluster_stores=true
sm_vol_log_reads=true
sm_chkpt_interval=5000
sm_shutdown_clean=false
sm_bufferpool_swizzle=false
sm_truncate_log=false
sm_no_db=false
sm_write_elision=true
EOF

function startTrimLoop()
{
    while true; do
        sleep 60;
        # sudo -n fstrim ${MOUNTPOINT[log]};
        # sudo -n fstrim ${MOUNTPOINT[db]};
        # sudo -n fstrim ${MOUNTPOINT[archive]};
    done
}

function beforeHook()
{
    echo -n "Loading snapshot for DB ... "
    load_snapshot.sh db-$SF
    [ $? -eq 0 ] || return 1;
    echo "OK"

    sudo /sbin/sysctl vm.drop_caches=3

    # startTrimLoop &
    # TRIMPID=$!
}

function afterHook()
{
    # kill -9 $TRIMPID > /dev/null 2>&1
    # zapps agglog -l ${MOUNTPOINT[log]}/log \
    #     -t xct_end \
    #     -b benchmark_start \
    #     > agglog.txt

    # zapps xctlatency -l ${MOUNTPOINT[log]}/log > xctlatency.txt
    zapps propstats -l ${MOUNTPOINT[log]}/log
    echo
}
