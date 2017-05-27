#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SF=75
THREADS=8

declare -A CFG

CFG["buffersizes-500"]=" --sm_bufpoolsize=500"
CFG["buffersizes-1000"]=" --sm_bufpoolsize=1000"
CFG["buffersizes-2000"]=" --sm_bufpoolsize=2000"
CFG["buffersizes-4000"]=" --sm_bufpoolsize=4000"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
queried_sf=$SF
threads=$THREADS
duration=300
asyncCommit=true
sm_log_benchmark_start=true
sm_vol_o_direct=true
sm_vol_cluster_stores=true
sm_cleaner_interval=-1
sm_chkpt_interval=5000
sm_shutdown_clean=false
sm_bufferpool_swizzle=false
sm_archiving=false
sm_truncate_log=false
sm_no_db=false
sm_write_elision=false
EOF

function startTrimLoop()
{
    while true; do
        sleep 60;
        sudo -n fstrim ${MOUNTPOINT[log]};
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
        > agglog.txt

    # zapps xctlatency -l ${MOUNTPOINT[log]}/log > xctlatency.txt
}
