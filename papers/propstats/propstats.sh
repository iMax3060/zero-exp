#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

declare -A CFG

# CFG[log_based]=" --sm_cleaner_decoupled=true"
# CFG[oldest_2k]="    --sm_cleaner_policy oldest_lsn       --sm_cleaner_num_candidates 2000"
# CFG[oldest_20k]="  --sm_cleaner_policy oldest_lsn       --sm_cleaner_num_candidates 20000"
CFG[oldest_200k]="  --sm_cleaner_policy oldest_lsn       --sm_cleaner_num_candidates 200000"
CFG[mixed_200k]="  --sm_cleaner_policy mixed       --sm_cleaner_num_candidates 200000"
# CFG[hottest_2k]="   --sm_cleaner_policy highest_refcount --sm_cleaner_num_candidates 2000"
# CFG[hottest_20k]=" --sm_cleaner_policy highest_refcount --sm_cleaner_num_candidates 20000"
# CFG[hottest_200k]=" --sm_cleaner_policy highest_refcount --sm_cleaner_num_candidates 200000"
# CFG[coldest_2k]="   --sm_cleaner_policy lowest_refcount  --sm_cleaner_num_candidates 2000"
# CFG[coldest_20k]=" --sm_cleaner_policy lowest_refcount  --sm_cleaner_num_candidates 20000"
# CFG[coldest_200k]=" --sm_cleaner_policy lowest_refcount  --sm_cleaner_num_candidates 200000"
# CFG[clustered_8]="  --sm_cleaner_min_write_size=8"
# CFG[clustered_32]=" --sm_cleaner_min_write_size=32"
# CFG[no_policy]="    --sm_cleaner_num_candidates 0"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
threads=20
queried_sf=100
duration=1200
warmup=1
sm_bufpoolsize=30000
sm_cleaner_workspace_size=1024
sm_cleaner_ignore_metadata=true
sm_cleaner_interval=0
sm_chkpt_interval=5
sm_log_delete_old_partitions=false
sm_shutdown_clean=false
sm_archiving=true
sm_archiver_eager=true
sm_archiver_workspace_size=1024
EOF

LOGDIR=${MOUNTPOINT[log]}/log

function beforeHook()
{
    load_snapshot.sh tpcc-100
    sudo -n fstrim ${MOUNTPOINT[archive]}
}

function afterHook()
{
    zapps propstats -l $LOGDIR
    # zapps dbscan -d /mnt/db/db > dbscan.txt
    zapps agglog -l $LOGDIR
}
