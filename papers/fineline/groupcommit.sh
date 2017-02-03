#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SF=80
THREADS=20

declare -A CFG

CFG["grpcmt-0_0"]=" --sm_group_commit_size=0 --sm_group_commit_timeout=0"
# CFG["grpcmt-256_0"]=" --sm_group_commit_size=256 --sm_group_commit_timeout=0"
# CFG["grpcmt-4096_0"]=" --sm_group_commit_size=4096 --sm_group_commit_timeout=0"
# CFG["grpcmt-32768_0"]=" --sm_group_commit_size=32768 --sm_group_commit_timeout=0"
# CFG["grpcmt-0_1"]=" --sm_group_commit_size=0 --sm_group_commit_timeout=1"
# CFG["grpcmt-256_1"]=" --sm_group_commit_size=256 --sm_group_commit_timeout=1"
# CFG["grpcmt-4096_1"]=" --sm_group_commit_size=4096 --sm_group_commit_timeout=1"
# CFG["grpcmt-32768_1"]=" --sm_group_commit_size=32768 --sm_group_commit_timeout=1"
# CFG["grpcmt-0_10"]=" --sm_group_commit_size=0 --sm_group_commit_timeout=10"
# CFG["grpcmt-256_10"]=" --sm_group_commit_size=256 --sm_group_commit_timeout=10"
# CFG["grpcmt-4096_10"]=" --sm_group_commit_size=4096 --sm_group_commit_timeout=10"
# CFG["grpcmt-32768_10"]=" --sm_group_commit_size=32768 --sm_group_commit_timeout=10"
# CFG["grpcmt-0_100"]=" --sm_group_commit_size=0 --sm_group_commit_timeout=100"
# CFG["grpcmt-256_100"]=" --sm_group_commit_size=256 --sm_group_commit_timeout=100"
# CFG["grpcmt-4096_100"]=" --sm_group_commit_size=4096 --sm_group_commit_timeout=100"
# CFG["grpcmt-32768_100"]=" --sm_group_commit_size=32768 --sm_group_commit_timeout=100"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
queried_sf=$SF
threads=$THREADS
duration=1200
asyncCommit=true
sm_bufpoolsize=80000
sm_vol_o_direct=true
sm_cleaner_interval=5000
sm_chkpt_interval=5000
sm_log_delete_old_partitions=false
sm_vol_log_reads=false
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
        # sudo -n fstrim ${MOUNTPOINT[archive]};
    done
}

function beforeHook()
{
    echo -n "Loading snapshot for grpcmt ... "
    load_snapshot.sh grpcmt-$SF
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
