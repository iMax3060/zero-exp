#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SF=750
SNAPSHOT=db-$SF

declare -A CFG

CFG["scalability-1"]=" --threads 1"
CFG["scalability-2"]=" --threads 2"
CFG["scalability-3"]=" --threads 3"
CFG["scalability-4"]=" --threads 4"
CFG["scalability-6"]=" --threads 6"
CFG["scalability-8"]=" --threads 8"
CFG["scalability-12"]=" --threads 12"
CFG["scalability-16"]=" --threads 16"
CFG["scalability-20"]=" --threads 20"
CFG["scalability-24"]=" --threads 24"
CFG["scalability-28"]=" --threads 28"
CFG["scalability-32"]=" --threads 32"
CFG["scalability-48"]=" --threads 48"
CFG["scalability-56"]=" --threads 56"
CFG["scalability-64"]=" --threads 64"
CFG["scalability-72"]=" --threads 72"
CFG["scalability-80"]=" --threads 80"
CFG["scalability-88"]=" --threads 88"
CFG["scalability-96"]=" --threads 96"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
queried_sf=$SF
duration=300
asyncCommit=true
sm_bufpoolsize=60000
sm_vol_o_direct=true
sm_cleaner_interval=-1
sm_chkpt_interval=5000
sm_chkpt_log_based=false
sm_bufferpool_swizzle=false
sm_archiving=false
sm_shutdown_clean=false
sm_truncate_log=false
sm_vol_cluster_stores=true
sm_log_o_direct=false
sm_group_commit_size=2097152
EOF

# warmup=true
# crashDelay=20

function startTrimLoop()
{
    sudo /sbin/sysctl vm.drop_caches=3
    while true; do
        sleep 60;
        # sudo -n fstrim ${MOUNTPOINT[log]};
        # sudo -n fstrim ${MOUNTPOINT[archive]};
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
        > agglog.txt

    zapps xctlatency -l ${MOUNTPOINT[log]}/log > xctlatency.txt
}
