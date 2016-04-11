#!/bin/bash

ARCH_DEV=sdc
DB_DEV=sdd
BACKUP_DEV=sde

SEQ_SEGSIZE=8192

EXPDIR=$1
PLOTDIR=gnuplot

if [ -z "$EXPDIR" ]; then
    echo "Missing argument: exp dir"
    exit 1
fi

# log archiver block size in KB
LA_BLOCK_SIZE=1024

# la_block_reads restore_multiple_segments 
SIMPLE_STATS="restore_time_replay
    restore_time_read
    backup_not_prefetched
    backup_evict_segment
    backup_eviction_stuck
    restore_time_write
    restore_time_openscan"
CALC_STATS="bandwidth la_read_efficiency total_times segments_per_iter" 

function sortfile() {
    grep -v "SEQ" $1 | sort -n -t 1 > tmp.txt
    grep "SEQ" $1 >> tmp.txt
    mv tmp.txt $1
}

for s in $SIMPLE_STATS; do
    rm -f $EXPDIR/"$s".txt
done
for s in $CALC_STATS; do
    rm -f $EXPDIR/"$s".txt
done

for d in $EXPDIR/restore-*; do
    d=$(basename $d)
    SEGSIZE=$((2 * ${d#restore-}))
    # if [ $SEGSIZE -ge 1024 ]; then
        # TITLE=$((SEGSIZE/1024))MB
    # else
        TITLE=$((SEGSIZE))KB
    # fi

    if [[ $SEGSIZE =~ ^[0-9]+\-[[:alpha:]]+$ ]]; then
        SEGSIZE=${SEGSIZE%%-*}
    fi

    if [[ "$SEGSIZE" == "seq" ]]; then
        # 1024 is the default segment size (assuming it's used in seq)
        #SEGSIZE=$(grep restore_backup_reads $d/out1.txt | tail -n 1 | awk '{ print $2 * 1024 }')
        SEGSIZE=$SEQ_SEGSIZE
        TITLE="SEQ"
    fi

    for s in $SIMPLE_STATS; do
        grep "$s" $EXPDIR/$d/out1.txt |
        awk -v segsize=$TITLE '{ print segsize, $2 }' \
            >> $EXPDIR/"$s".txt
    done

    cat $EXPDIR/$d/agglog.txt |
    awk -v segsize=$SEGSIZE -v title=$TITLE \
        'BEGIN { cnt = 0; sum = 0; began = false; } 
         { 
             if (!began) { began = $2; }
             if (began) { sum += $2; cnt++; }
         }
         END { printf("%s %.2f\n", title, (sum/cnt)*segsize/1024) }' \
        >> $EXPDIR/bandwidth.txt

    logvol=$(grep restore_log_volume $EXPDIR/$d/out1.txt | tail -n 1 | awk '{print $2}')
    lareads=$(grep la_read_volume $EXPDIR/$d/out1.txt | awk '{ print $2 }')
    if [ -z "$lareads" ]; then logvol=0; lareads=1; fi
    echo $TITLE $(bc -l <<< "$logvol / $lareads") >> $EXPDIR/la_read_efficiency.txt

    segcount=$(grep restore_segment_count $EXPDIR/$d/out1.txt | awk '{print $2}')
    invocations=$(grep restore_invocations $EXPDIR/$d/out1.txt | awk '{ print $2 }')
    echo $TITLE $(bc -l <<< "$segcount / $invocations") >> $EXPDIR/segments_per_iter.txt

    echo $TITLE $(wc -l $EXPDIR/$d/agglog.txt) >> $EXPDIR/total_times.txt

    cat $EXPDIR/$d/iostat.txt |
    awk -v segsize=$TITLE -v arch=$ARCH_DEV -v db=$DB_DEV -v backup=$BACKUP_DEV \
        'BEGIN { track = 0; }
         { if (track == 3) { print a, b, c; track = 0 } }
         $1 == arch { a = $6; track++ }
         $1 == backup { b = $6; track++ }
         $1 == db { c = $7; track++}' \
        > $EXPDIR/iostat_"$TITLE".txt

    # GENERATE PER_SEGMENT PLOTS
    gnuplot -e "outfile='"$EXPDIR"/iostat_"$TITLE".png'; file='"$EXPDIR"/iostat_"$TITLE".txt'; segsize='"$TITLE"'" $PLOTDIR/iostat.gp
done

for f in $CALC_STATS $SIMPLE_STATS; do
    sortfile $EXPDIR/$f.txt;

    # GENERATE GLOBAL PLOTS
    gnuplot -e "outfile='"$EXPDIR"/"$f".png'; file='"$EXPDIR"/"$f".txt'" $PLOTDIR/bars.gp
done

gnuplot -e "dir='"$EXPDIR"'" $PLOTDIR/restore_times.gp
