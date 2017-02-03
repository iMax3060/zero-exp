#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SF=60
THREADS=8

declare -A CFG

# CFG["buffersizes-100"]=" --sm_bufpoolsize=100"
# CFG["buffersizes-200"]=" --sm_bufpoolsize=200"
# CFG["buffersizes-300"]=" --sm_bufpoolsize=300"
# CFG["buffersizes-400"]=" --sm_bufpoolsize=400"
# CFG["buffersizes-500"]=" --sm_bufpoolsize=500"
# CFG["buffersizes-600"]=" --sm_bufpoolsize=600"
# CFG["buffersizes-700"]=" --sm_bufpoolsize=700"
# CFG["buffersizes-800"]=" --sm_bufpoolsize=800"
# CFG["buffersizes-1200"]=" --sm_bufpoolsize=1200"
# CFG["buffersizes-1600"]=" --sm_bufpoolsize=1600"
# CFG["buffersizes-2400"]=" --sm_bufpoolsize=2400"
CFG["buffersizes-20000"]=" --sm_bufpoolsize=20000"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
queried_sf=$SF
threads=$THREADS
duration=300
sm_vol_o_direct=true
sm_cleaner_interval=0
sm_chkpt_interval=5000
sm_log_delete_old_partitions=false
sm_bufferpool_swizzle=true
sm_archiving=true
sm_shutdown_clean=false
sm_truncate_log=true
sm_archiver_workspace_size=2048
sm_archiver_eager=true
sm_archiver_merging=true
sm_no_db=true
sm_batch_warmup=true
EOF

function startTrimLoop()
{
    while true; do
        sleep 60;
        # sudo -n fstrim ${MOUNTPOINT[log]};
        sudo -n fstrim ${MOUNTPOINT[archive]};
    done
}

function beforeHook()
{
    echo -n "Loading snapshot for nodb ... "
    load_snapshot.sh nodb-$SF
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
