#!/bin/bash

source config.sh || (echo "config.sh not found!"; exit)

SF=750

declare -A CFG

CFG["restore-5000"]=" --sm_bufpoolsize=5000"
# CFG["restore-25000"]=" --sm_bufpoolsize=25000"
# CFG["restore-30000"]=" --sm_bufpoolsize=30000"
# CFG["restore-35000"]=" --sm_bufpoolsize=35000"
# CFG["restore-40000"]=" --sm_bufpoolsize=40000"
# CFG["restore-45000"]=" --sm_bufpoolsize=45000"
# CFG["restore-50000"]=" --sm_bufpoolsize=50000"

# BASE CONFIGURATION
BASE_CFG=_baseconfig.conf 
cat > $BASE_CFG << EOF
benchmark=tpcc
threads=20
queried_sf=$SF
duration=600
failDelay=600
sm_restore_sched_singlepass=true
sm_restore_segsize=4096
sm_restore_reuse_buffer=true
sm_restore_max_read_size=1048576
sm_restore_preemptive=true
sm_restore_instant=true
warmup=1
sm_vol_readonly=false
sm_vol_log_reads=true
sm_vol_o_direct=true
sm_cleaner_workspace_size=1024
sm_cleaner_ignore_metadata=true
sm_cleaner_interval=5000
sm_chkpt_interval=5
sm_log_delete_old_partitions=false
sm_shutdown_clean=false
sm_archiving=true
sm_archiver_eager=true
sm_archiver_workspace_size=1024
sm_bufferpool_swizzle=false
EOF

function startTrimLoop()
{
    while true; do
        sleep 60;
        sudo -n fstrim ${MOUNTPOINT[log]};
        sudo -n fstrim ${MOUNTPOINT[archive]};
    done
}

function beforeHook()
{
    echo -n "Loading snapshot ... "
    load_snapshot.sh tpcc-$SF-restore
    [ $? -eq 0 ] || return 1;
    echo "OK"

    echo -n "Copying backup ... "
    rsync -a ${MOUNTPOINT[db]}/db ${MOUNTPOINT[backup]}/backup
    echo "OK"

    echo -n "Adding backup file ... "
    LASTPART=0
    for l in ${MOUNTPOINT[log]}/log/log.*; do
        FNAME=$(basename "$l")
        EXT="${FNAME##*.}"
        if [ $EXT -gt $LASTPART ]; then
            LASTPART=$EXT
        fi
    done

    zapps addbackup -l ${MOUNTPOINT[log]}/log -f ${MOUNTPOINT[backup]}/backup --lsn $LASTPART".0"
    [ $? -eq 0 ] || return 1;
    echo "OK"

    startTrimLoop &
    TRIMPID=$!
}

function afterHook()
{
    kill -9 $TRIMPID > /dev/null 2>&1
    zapps agglog -l ${MOUNTPOINT[log]}/log \
        -t xct_end \
        -t restore_begin \
        -t restore_segment \
        -t restore_end \
        -t page_write \
        -t page_read \
        > agglog.txt

    zapps xctlatency -l ${MOUNTPOINT[log]}/log > xctlatency.txt
}
