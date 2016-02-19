#!/bin/bash

RUN_GDB=false
if [[ "$1" == "--debug" ]]; then
    RUN_GDB=true
    shift
fi

iostat -dmtx 1 > iostat.txt 2> /dev/null &
IOSTAT_PID=$!

mpstat 1 > mpstat.txt 2> /dev/null &
MPSTAT_PID=$!

CMD="$*"
EXIT_CODE=0

echo -n "Running kits benchmark ... "
if $RUN_GDB; then
    DEBUG_FLAGS="restore.cpp log_spr.cpp" gdb -ex run --args zapps $CMD
else
    zapps $CMD 1> out1.txt 2> out2.txt
    EXIT_CODE=$?
fi
echo "OK"

kill $IOSTAT_PID > /dev/null 2>&1
kill $MPSTAT_PID > /dev/null 2>&1

exit $EXIT_CODE
