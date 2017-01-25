#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SF=60

declare -A CFG

# CFG["db-100"]=" --sm_bufpoolsize=100"
# CFG["db-200"]=" --sm_bufpoolsize=200"
# CFG["db-300"]=" --sm_bufpoolsize=300"
# CFG["db-400"]=" --sm_bufpoolsize=400"
# CFG["db-500"]=" --sm_bufpoolsize=500"
# CFG["db-600"]=" --sm_bufpoolsize=600"
# CFG["db-700"]=" --sm_bufpoolsize=700"
# CFG["db-800"]=" --sm_bufpoolsize=800"
# CFG["db-1200"]=" --sm_bufpoolsize=1200"
# CFG["db-1600"]=" --sm_bufpoolsize=1600"
# CFG["db-2400"]=" --sm_bufpoolsize=2400"
# CFG["db-3200"]=" --sm_bufpoolsize=3200"
# CFG["db-4000"]=" --sm_bufpoolsize=4000"
# CFG["db-4800"]=" --sm_bufpoolsize=4800"
# CFG["db-5600"]=" --sm_bufpoolsize=5600"
# CFG["db-6400"]=" --sm_bufpoolsize=6400"
# CFG["db-7200"]=" --sm_bufpoolsize=7200"
CFG["db-8000"]=" --sm_bufpoolsize=8000"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
queried_sf=$SF
threads=20
duration=300
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
    load_snapshot.sh tpcc-$SF-loaded
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
        -t page_write \
        -t page_read \
        > agglog.txt

    # zapps xctlatency -l ${MOUNTPOINT[log]}/log > xctlatency.txt
}
