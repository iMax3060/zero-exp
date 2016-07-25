#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

declare -A CFG

# CFG[buffer_2000]="  --sm_bufpoolsize 2000"
# CFG[buffer_1500]="  --sm_bufpoolsize 5000"
# CFG[buffer_1300]="  --sm_bufpoolsize 3000"
# CFG[buffer_1000]="  --sm_bufpoolsize 1000"
# CFG[buffer_800]="  --sm_bufpoolsize 800"
# CFG[buffer_600]="  --sm_bufpoolsize 600"
CFG[buffer_400]="  --sm_bufpoolsize 400"
# CFG[buffer_200]="  --sm_bufpoolsize 200"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
threads=10
queried_sf=10
duration=120
warmup=0
sm_cleaner_workspace_size=64
sm_cleaner_ignore_metadata=false
sm_cleaner_interval=2000
sm_chkpt_interval=5
sm_log_delete_old_partitions=false
sm_shutdown_clean=false
sm_archiving=false
EOF

LOGDIR=${MOUNTPOINT[log]}/log

function beforeHook()
{
    load_snapshot.sh tpcc-10
}

function afterHook()
{
    zapps agglog -l $LOGDIR
}
