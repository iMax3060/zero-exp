#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

# CHANGE THIS LINE ONLY TO SWITCH BETWEEN FL, WAL, AND LSM
# EXP_PREFIX="fl"
EXP_PREFIX="wal"
# EXP_PREFIX="lsm"

# each SF genereates about 100MB of data, so this is 80GB
SF=800
# each X million transactions touches 1GB of data
# TRXS=$((5*1000*1000))
TRXS=$((500*1000*1000))
BENCH=ycsb
THREADS=20
BUFFER_SIZE_MB=200000

BASE_CFG=_baseconfig_"$EXP_PREFIX".conf
SNAPSHOT="$EXP_PREFIX"_"$SF"
ZAPPS_BIN=zapps_$EXP_PREFIX
ZAPPS=zapps
[ -f $ZAPPS_BIN ] || die "$ZAPPS_BIN not found"
if [ -f $ZAPPS ]; then
    [ -L $ZAPPS ] || die "zapps file exists and it's not a symlink"
    rm $ZAPPS
fi
ln -s $ZAPPS_BIN $ZAPPS

declare -A AGGRESSIVE_OPT
AGGRESSIVE_OPT["fl"]="--sm_archiver_merge_fanin=4 --sm_page_img_compression=$((128*1024))"
AGGRESSIVE_OPT["wal"]="--sm_cleaner_interval=0"
AGGRESSIVE_OPT["lsm"]="--leveldb_max_file_size=$((2*1024*1024)) --leveldb_write_buffer_size=$((4*1024*1024))"

declare -A CFG
#(TPC-C, YCSB/TPC-B) x (read-only, read-heavy, balanced, write-heavy) x (low-skew, high-skew) x (normal-propagation, aggressive) x (Zero, FL, LevelDB) X (SlowSSD, FastSSD, Disk, DRAM)
# CFG[""$EXP_PREFIX"_ronly"]=" --updateFreq=0"
CFG[""$EXP_PREFIX"_rheavy"]=" --updateFreq=10"
# CFG[""$EXP_PREFIX"_balanced"]=" --updateFreq=50"
# CFG[""$EXP_PREFIX"_balanced_aggressive"]=" --updateFreq=50 ${AGGRESSIVE_OPT[$EXP_PREFIX]}"
# CFG[""$EXP_PREFIX"_wheavy"]=" --updateFreq=90"
# CFG[""$EXP_PREFIX"_wheavy_aggressive"]=" --updateFreq=90 ${AGGRESSIVE_OPT[$EXP_PREFIX]}"
# CFG[""$EXP_PREFIX"_wheavy_skew"]=" --updateFreq=90 --skew"

# FINELINE OPTIONS
cat > _baseconfig_fl.conf << EOF
benchmark=$BENCH
queried_sf=$SF
threads=$THREADS
trxs=$TRXS
sm_bufpoolsize=$BUFFER_SIZE_MB
sm_log_delete_old_partitions=true
sm_evict_unarchived=false
sm_archiver_merge_fanin=8
EOF

# WAL options
cat > _baseconfig_wal.conf << EOF
benchmark=$BENCH
queried_sf=$SF
threads=$THREADS
trxs=$TRXS
sm_bufpoolsize=$BUFFER_SIZE_MB
sm_restart_instant=true
sm_cleaner_decoupled=false
sm_cleaner_interval=500
sm_chkpt_print_propstats=false
sm_log_page_evictions=false
sm_ticker_print_tput=true
sm_log_benchmark_start=false
sm_log_delete_old_partitions=true
sm_vol_o_direct=false
sm_vol_cluster_stores=true
sm_vol_log_reads=false
sm_chkpt_interval=5000
sm_shutdown_clean=false
sm_bufferpool_swizzle=false
sm_truncate_log=false
sm_no_db=false
sm_write_elision=false
sm_archiving=false
EOF

# LSM OPTIONS
cat > _baseconfig_lsm.conf << EOF
benchmark=$BENCH
queried_sf=$SF
threads=$THREADS
trxs=$TRXS
leveldb_max_file_size=$((512*1024*1024))
leveldb_write_buffer_size=$((1024*1024*1024))
leveldb_block_cache_size=$(($BUFFER_SIZE_MB*1024*1024))
leveldb_use_compression=false
leveldb_logdir=${MOUNTPOINT[leveldb]}/leveldb
EOF

# function startTrimLoop()
# {
#     while true; do
#         sudo -n fstrim ${MOUNTPOINT[log]};
#         sudo -n fstrim ${MOUNTPOINT[archive]};
#         sleep 60;
#     done
# }

function beforeHook()
{
    echo -n "Loading snapshot $SNAPSHOT ... "
    ./load_snapshot.sh $SNAPSHOT
    [ $? -eq 0 ] || return 1;
    echo "OK"

    sudo -n /sbin/sysctl vm.drop_caches=3
    # startTrimLoop &
    # TRIMPID=$!
}

function afterHook()
{
    # kill -9 $TRIMPID > /dev/null 2>&1
    # zapps agglog -l ${MOUNTPOINT[log]}/log \
    #     -t xct_end \
    #     -b benchmark_start \
    #     > agglog.txt
    if [ -f tput.txt ]; then
        cp tput.txt agglog.txt
    fi
    grep "Secs" out1.txt > duration.txt

    # zapps xctlatency -l ${MOUNTPOINT[log]}/log > xctlatency.txt
    # zapps tracerestore -l ${MOUNTPOINT[log]}/log > tracerestore.txt
}

