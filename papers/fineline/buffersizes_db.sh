#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SF=75
THREADS=8

declare -A CFG

# CFG["buffersizes-500"]=" --sm_bufpoolsize=500"
# CFG["buffersizes-1000"]=" --sm_bufpoolsize=1000"
# CFG["buffersizes-1500"]=" --sm_bufpoolsize=1500"
# CFG["buffersizes-2000"]=" --sm_bufpoolsize=2000"
# CFG["buffersizes-2500"]=" --sm_bufpoolsize=2500"
# CFG["buffersizes-3000"]=" --sm_bufpoolsize=3000"
# CFG["buffersizes-3500"]=" --sm_bufpoolsize=3500"
CFG["buffersizes-4000"]=" --sm_bufpoolsize=4000"
# CFG["buffersizes-5000"]=" --sm_bufpoolsize=5000"
# CFG["buffersizes-6000"]=" --sm_bufpoolsize=6000"
# CFG["buffersizes-7000"]=" --sm_bufpoolsize=7000"
# CFG["buffersizes-8000"]=" --sm_bufpoolsize=8000"
# CFG["buffersizes-9000"]=" --sm_bufpoolsize=9000"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
queried_sf=$SF
threads=$THREADS
duration=2700
asyncCommit=true
sm_cleaner_workspace_size=1024
sm_log_benchmark_start=true
sm_log_delete_old_partitions=false
sm_vol_o_direct=true
sm_vol_cluster_stores=true
sm_cleaner_interval=0
sm_chkpt_interval=5000
sm_shutdown_clean=false
sm_bufferpool_swizzle=false
sm_archiving=false
sm_truncate_log=false
sm_async_eviction=false
sm_no_db=false
sm_write_elision=false
EOF

function startTrimLoop()
{
    while true; do
        sleep 60;
        sudo -n fstrim ${MOUNTPOINT[log]};
        sudo -n fstrim ${MOUNTPOINT[db]};
        sudo -n fstrim ${MOUNTPOINT[archive]};
    done
}

function beforeHook()
{
    echo -n "Loading snapshot for DB ... "
    load_snapshot.sh db-$SF
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
}
