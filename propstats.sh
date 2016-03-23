#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

declare -A CFG

CFG[oldest_5k]="    --sm_cleaner_policy oldest_lsn       --sm_cleaner_num_candidates 5000"
CFG[oldest_160k]="  --sm_cleaner_policy oldest_lsn       --sm_cleaner_num_candidates 160000"
CFG[hottest_5k]="   --sm_cleaner_policy highest_refcount --sm_cleaner_num_candidates 5000"
CFG[hottest_160k]=" --sm_cleaner_policy highest_refcount --sm_cleaner_num_candidates 160000"
CFG[coldest_5k]="   --sm_cleaner_policy lowest_refcount  --sm_cleaner_num_candidates 5000"
CFG[coldest_160k]=" --sm_cleaner_policy lowest_refcount  --sm_cleaner_num_candidates 160000"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
threads=20
queried_sf=100
duration=600
sm_bufpoolsize=70000
sm_cleaner_workspace_size=1024
sm_chkpt_interval=5
sm_log_delete_old_partitions=false
EOF

function beforeHook()
{
    load_snapshot.sh tpcc-100
}

function afterHook()
{
    zapps propstats -l ${MOUNTPOINT[log]}/log
}
