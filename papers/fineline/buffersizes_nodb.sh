#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SF=60

declare -A CFG

CFG["nodb-100"]=" --sm_bufpoolsize=100"
CFG["nodb-200"]=" --sm_bufpoolsize=200"
CFG["nodb-300"]=" --sm_bufpoolsize=300"
CFG["nodb-400"]=" --sm_bufpoolsize=400"
CFG["nodb-500"]=" --sm_bufpoolsize=500"
CFG["nodb-600"]=" --sm_bufpoolsize=600"
CFG["nodb-700"]=" --sm_bufpoolsize=700"
CFG["nodb-800"]=" --sm_bufpoolsize=800"

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
sm_shutdown_clean=false
sm_bufferpool_swizzle=true
sm_archiving=true
sm_shutdown_clean=true
sm_truncate_log=true
sm_archiver_workspace_size=2048
sm_archiver_eager=true
sm_no_db=true
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
    load_snapshot.sh tpcc-$SF-nodb-loaded
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
