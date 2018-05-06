#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SF=75
# SNAPSHOT=fl-"$SF"-opt
# SNAPSHOT=fl-"$SF"-recover-merged
# SNAPSHOT=db-"$SF"
SNAPSHOT=db-"$SF"-recover-cleaner

declare -A CFG


# CFG["warmup_fl-1"]=" --threads=1"
# CFG["warmup_fl-2"]=" --threads=2"
# CFG["warmup_fl-4"]=" --threads=4"
# CFG["warmup_fl-8"]=" --threads=8"
# CFG["warmup_fl-12"]=" --threads=12"
CFG["warmup_fl-16"]=" --threads=16"
# CFG["warmup_fl-20"]=" --threads=20"

# CFG["warmup_fl-1000"]=" --sm_bufpoolsize=1000"
# CFG["warmup_fl-2000"]=" --sm_bufpoolsize=2000"
# CFG["warmup_fl-3000"]=" --sm_bufpoolsize=3000"
# CFG["warmup_fl-4000"]=" --sm_bufpoolsize=4000"
# CFG["warmup_fl-5000"]=" --sm_bufpoolsize=5000"
# CFG["warmup_fl-6000"]=" --sm_bufpoolsize=6000"
# CFG["warmup_fl-7000"]=" --sm_bufpoolsize=7000"
# CFG["warmup_fl-8000"]=" --sm_bufpoolsize=8000"
# CFG["warmup_fl-9000"]=" --sm_bufpoolsize=9000"
# CFG["warmup_fl-10000"]=" --sm_bufpoolsize=10000"
# CFG["warmup_fl-11000"]=" --sm_bufpoolsize=11000"
# CFG["warmup_fl-12000"]=" --sm_bufpoolsize=12000"

# FINELINE OPTIONS
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
queried_sf=75
threads=16
duration=600
sm_bufpoolsize=40000
asyncCommit=true
sm_log_partition_size=1024
sm_archiver_block_size=$((8*1024*1024))
sm_arch_fsync_frequency=1
sm_async_eviction=false
sm_log_delete_old_partitions=true
sm_bufferpool_swizzle=false
sm_log_page_evictions=false
sm_log_page_fetches=false
sm_ticker_print_tput=true
sm_page_img_compression=0
sm_evict_unarchived=false
EOF

# # # WAL+DB options
# BASE_CFG=_baseconfig.conf 
# cat > $BASE_CFG << EOF
# benchmark=tpcc
# queried_sf=75
# threads=16
# duration=330
# asyncCommit=true
# sm_bufpoolsize=40000
# sm_restart_instant=true
# sm_cleaner_decoupled=false
# sm_cleaner_interval=-1
# sm_chkpt_print_propstats=false
# sm_log_page_evictions=false
# sm_ticker_print_tput=true
# sm_log_benchmark_start=false
# sm_log_delete_old_partitions=false
# sm_vol_o_direct=true
# sm_vol_cluster_stores=true
# sm_vol_log_reads=false
# sm_chkpt_interval=5000
# sm_shutdown_clean=false
# sm_bufferpool_swizzle=false
# sm_truncate_log=false
# sm_no_db=false
# sm_write_elision=false
# sm_archiving=false
# EOF

function startTrimLoop()
{
    sudo /sbin/sysctl vm.drop_caches=3
    # while true; do
    #     sudo -n fstrim ${MOUNTPOINT[log]};
    #     sudo -n fstrim ${MOUNTPOINT[archive]};
    #     sleep 60;
    # done
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
    # zapps agglog -l ${MOUNTPOINT[log]}/log \
    #     -t xct_end \
    #     -b benchmark_start \
    #     > agglog.txt
    cp tput.txt agglog.txt

    # zapps xctlatency -l ${MOUNTPOINT[log]}/log > xctlatency.txt
    # zapps tracerestore -l ${MOUNTPOINT[log]}/log > tracerestore.txt
}
