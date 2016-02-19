#!/bin/bash


SF=$1
DURATION=$2

DEVTYPE="ssd"

[ ! -z "$SF" ] || exit 1
[ ! -z "$DURATION" ] || DURATION=300

THREADS=$(( MAX_THREADS > SF ? SF : MAX_THREADS ))

set -e
mkdir -p $BASEDIR

[ -d $BASEDIR ] || exit 1

mkdir -p $LOADDIR
rm -rf $LOADDIR/*

mkdir -p $BENCHDIR
rm -rf $BENCHDIR/*

echo -n "Loading DB ... "

gdb --args \
zapps kits -b tpcc --load \
    -d $DBFILE -l $LOGDIR -a $ARCHDIR \
    --bufsize $BUFSIZE --logsize $LOGSIZE --archWorkspace $WORKSPACE \
    -q $SF -t $THREADS --sm_shutdown_clean true \
    --sm_decoupled_cleaner true \
    --truncateLog true \

    # 1> out1.txt 2> out2.txt
echo "OK"

echo -n "Copying data ... "
# backup is not required -- it will be copied to bench dir below
# mkdir -p $LOADDIR/archive
# rsync -aq --copy-links --delete $ARCHDIR/ $LOADDIR/archive/
mkdir -p $LOADDIR/log
rsync -aq --copy-links --delete $LOGDIR/ $LOADDIR/log/
rsync -aq --copy-links --delete $DBFILE $LOADDIR/db
cp out?.txt $LOADDIR/
echo "OK"

echo -n "Running benchmark ... "

# gdb --args \
# zapps kits -b tpcc \
#     -d $DBFILE -l $LOGDIR -a $ARCHDIR\
#     --bufsize $BUFSIZE --logsize $LOGSIZE --archWorkspace $WORKSPACE \
#     -q $SF -t $THREADS \
#     --duration $DURATION --sm_shutdown_clean false \
#     --sm_restart_instant true \
#     --sm_restart_log_based_redo false \
#     --sm_vol_readonly true \
    
#     # 1> out1.txt 2> out2.txt

# gdb --args \
# zapps kits -b tpcc \
#     -l $LOGDIR -a $ARCHDIR \
#     --bufsize $BUFSIZE --logsize $LOGSIZE --archWorkspace $((WORKSPACE / 10)) \
#     -q $SF -t $THREADS \
#     --eager --truncateLog --duration $DURATION \
#     --sm_archiver_bucket_size 128 \
#     1> out1.txt 2> out2.txt

echo "OK"

# echo -n "Copying data ... "
# # rsync -aq --copy-links --delete $DBFILE $BENCHDIR/db
# # # rsync -aq --copy-links --delete $ARCHDIR/ $BENCHDIR/archive/
# rsync -aq --copy-links --delete $LOGDIR/ $BENCHDIR/log/
# cp out?.txt $BENCHDIR/
# echo "OK"
