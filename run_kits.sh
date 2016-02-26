#!/bin/bash

source functions.sh || (echo "functions.sh not found!"; exit)
source config.sh || (echo "config.sh not found!"; exit)

RUN_GDB=false
if [[ "$1" == "--debug" ]]; then
    RUN_GDB=true
    shift
fi

iostat -dmtx 1 > iostat.txt 2> /dev/null &
IOSTAT_PID=$!

mpstat 1 > mpstat.txt 2> /dev/null &
MPSTAT_PID=$!

DBDIR=${MOUNTPOINT[db]}
if [ "${USE_BTRFS[db]}" == "true" ]; then DBDIR=$DBDIR/old; fi
LOGDIR=${MOUNTPOINT[log]}
if [ "${USE_BTRFS[log]}" == "true" ]; then LOGDIR=$LOGDIR/old; fi
ARCHDIR=${MOUNTPOINT[archive]}
if [ "${USE_BTRFS[log]}" == "true" ]; then ARCHDIR=$ARCHDIR/old; fi

CMD="zapps kits $* -d $DBDIR/db -l $LOGDIR/log -a $ARCHDIR/archive"
EXIT_CODE=0

echo -n "Running kits benchmark ... "
if $RUN_GDB; then
    gdb -ex run --args $CMD
else
    $CMD 1> out1.txt 2> out2.txt
    EXIT_CODE=$?
fi
echo "OK"

kill $IOSTAT_PID > /dev/null 2>&1
kill $MPSTAT_PID > /dev/null 2>&1

exit $EXIT_CODE
