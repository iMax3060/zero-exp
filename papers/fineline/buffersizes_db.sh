#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SF=750
THREADS=20

declare -A CFG

CFG["buffersizes-2500"]=" --sm_bufpoolsize=2500"
CFG["buffersizes-5000"]=" --sm_bufpoolsize=5000"
CFG["buffersizes-7500"]=" --sm_bufpoolsize=7500"
CFG["buffersizes-10000"]=" --sm_bufpoolsize=10000"
CFG["buffersizes-12500"]=" --sm_bufpoolsize=12500"
CFG["buffersizes-15000"]=" --sm_bufpoolsize=15000"
# CFG["buffersizes-20000"]=" --sm_bufpoolsize=20000"
# CFG["buffersizes-25000"]=" --sm_bufpoolsize=25000"
# CFG["buffersizes-30000"]=" --sm_bufpoolsize=30000"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
queried_sf=$SF
threads=$THREADS
duration=1200
asyncCommit=true
sm_vol_o_direct=true
sm_cleaner_interval=0
sm_chkpt_interval=5000
sm_log_delete_old_partitions=false
sm_vol_log_reads=true
sm_shutdown_clean=false
sm_bufferpool_swizzle=true
sm_archiving=false
sm_truncate_log=false
sm_no_db=false
sm_write_elision=true
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
        -b benchmark_start \
        -t xct_end \
        > agglog.txt

    # zapps xctlatency -l ${MOUNTPOINT[log]}/log > xctlatency.txt
}
