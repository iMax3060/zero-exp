#!/bin/bash

RUN_CMD="$HOME/hp/zero/build/tests/sm/stress_cleaner"

source config.sh || (echo "config.sh not found!"; exit)

function clean_up {
    kill $IOSTAT_PID > /dev/null 2>&1
}

declare -A CFG

CFG[oldest_2k]="    --sm_cleaner_policy oldest_lsn       --sm_cleaner_num_candidates 2000"
CFG[oldest_20k]="   --sm_cleaner_policy oldest_lsn       --sm_cleaner_num_candidates 20000"
CFG[oldest_200k]="  --sm_cleaner_policy oldest_lsn       --sm_cleaner_num_candidates 200000"
CFG[hottest_2k]="   --sm_cleaner_policy highest_refcount --sm_cleaner_num_candidates 2000"
CFG[hottest_20k]="  --sm_cleaner_policy highest_refcount --sm_cleaner_num_candidates 20000"
CFG[hottest_200k]=" --sm_cleaner_policy highest_refcount --sm_cleaner_num_candidates 200000"
CFG[coldest_2k]="   --sm_cleaner_policy lowest_refcount  --sm_cleaner_num_candidates 2000"
CFG[coldest_20k]="  --sm_cleaner_policy lowest_refcount  --sm_cleaner_num_candidates 20000"
CFG[coldest_200k]=" --sm_cleaner_policy lowest_refcount  --sm_cleaner_num_candidates 200000"
CFG[clustered_8]="  --sm_cleaner_min_write_size=8"
CFG[clustered_32]=" --sm_cleaner_min_write_size=32"
CFG[default]="      --sm_cleaner_num_candidates 0"

DBDIR=${MOUNTPOINT[db]}
ARCHDIR=${MOUNTPOINT[archive]}/archive
LOGDIR=/dev/shm/log

# BASE CONFIGURATION
BASE_CFG="
--trace-file=$HOME/pid_trace.txt
--sm_format=true
--sm_dbfile=$DBDIR/db
--sm_logdir=$LOGDIR
--sm_archiving=true
--sm_archdir=$ARCHDIR
--sm_bufpoolsize=30000
--sm_cleaner_workspace_size=1024
--sm_cleaner_ignore_metadata=true
--sm_cleaner_interval=0
--sm_chkpt_interval=5
--sm_shutdown_clean=false
--sm_ticker_enable=true
"

# Call clean_up when recieving one of these signals
trap clean_up SIGHUP SIGINT SIGTERM

for v in ${!CFG[@]}; do
    mkdir -p $v

    iostat -dmtx 1 > $v/iostat.txt 2> /dev/null &
    IOSTAT_PID=$!

    echo -n "Running $v ... "
    $RUN_CMD $BASE_CFG ${CFG[$v]} \
        > $v/out1.txt 2> $v/out2.txt
    echo "OK"

    zapps propstats -l $LOGDIR
    mv propstats.txt $v/
    mv writesizes.txt $v/

    clean_up
done
