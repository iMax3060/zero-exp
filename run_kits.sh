#!/bin/bash

source functions.sh || (echo "functions.sh not found!"; exit)
source config.sh || (echo "config.sh not found!"; exit)

function clean_up {
    kill -9 $IOSTAT_PID > /dev/null 2>&1
    kill -9 $MPSTAT_PID > /dev/null 2>&1
    kill -9 $VMSTAT_PID > /dev/null 2>&1
    kill -9 $FREE_PID > /dev/null 2>&1
    kill -9 $IOTOP_PID > /dev/null 2>&1
    kill -9 $DF_PID > /dev/null 2>&1
}

RUN_GDB=false
if [[ "$1" == "--debug" ]]; then
    RUN_GDB=true
    shift
fi

iostat -dmtx 1 > iostat.txt 2> /dev/null &
IOSTAT_PID=$!
mpstat 1 > mpstat.txt 2> /dev/null &
MPSTAT_PID=$!
vmstat 1 > vmstat.txt 2> /dev/null &
VMSTAT_PID=$!
sudo -n iotop -qtaP | grep "zapps kits" | grep -v "grep" > iotop.txt 2> /dev/null &
IOTOP_PID=$!
free -m -c 100000 -s 1 > free.txt 2> /dev/null &
FREE_PID=$!
rm -f df.txt
while true; do df -t ext4 >> df.txt; sleep 1; done &
DF_PID=$!

# Call clean_up when recieving one of these signals
trap clean_up SIGHUP SIGINT SIGTERM

KITS_OPTS=""

DBDIR=${MOUNTPOINT[db]}
if [ -n "$DBDIR" ]; then
    if [ "${USE_BTRFS[db]}" == "true" ]; then DBDIR=$DBDIR/new; fi
    KITS_OPTS+=" --sm_dbfile $DBDIR/db"
fi

LOGDIR=${MOUNTPOINT[log]}
if [ -n "$LOGDIR" ]; then
    if [ "${USE_BTRFS[log]}" == "true" ]; then LOGDIR=$LOGDIR/new; fi
    KITS_OPTS+=" --sm_logdir $LOGDIR/log"
fi

ARCHDIR=${MOUNTPOINT[archive]}
if [ -n "$ARCHDIR" ]; then
    if [ "${USE_BTRFS[archive]}" == "true" ]; then ARCHDIR=$ARCHDIR/new; fi
    KITS_OPTS+=" --sm_archdir $ARCHDIR/archive"
fi

CMD="./zapps kits $KITS_OPTS $*"
EXIT_CODE=0

if $RUN_GDB; then
    # echo "perf record -e cpu-clock -g --call-graph dwarf -F 97 $CMD"
    # perf record -e cpu-clock -g --call-graph dwarf -F 97 $CMD
    echo "gdb -ex run --args $CMD"
    gdb -ex run --args $CMD
    # echo "strace $CMD"
    # strace $CMD
    # echo "valgrind --tool=massif --threshold=0.01 $CMD"
    # valgrind --tool=massif --threshold=0.01 $CMD
    EXIT_CODE=$?
else
    echo "$CMD"
    $CMD 1> out1.txt 2> out2.txt
    EXIT_CODE=$?
fi

clean_up

exit $EXIT_CODE
