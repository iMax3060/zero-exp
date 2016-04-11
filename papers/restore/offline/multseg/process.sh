#!/bin/bash

ARCH_DEV=sdd
DB_DEV=sde
BACKUP_DEV=sdf

# log archiver block size in KB
LA_BLOCK_SIZE=1024

SIMPLE_STATS="la_block_reads restore_multiple_segments restore_time_replay restore_time_read
    restore_time_write restore_time_openscan"
CALC_STATS="bandwidth la_read_efficiency total_times" 

function sortfile() {
    sort -n -t 1 $1 > tmp.txt
    mv tmp.txt $1
}

for s in $SIMPLE_STATS; do
    rm -f "$s".txt
done
for s in $CALC_STATS; do
    rm -f "$s".txt
done

for d in restore-*; do
    SEGSIZE=${d#restore-}
    TITLE=$SEGSIZE

    if [[ $SEGSIZE =~ ^[0-9]+\-[[:alpha:]]+$ ]]; then
        SEGSIZE=${SEGSIZE%%-*}
    fi

    if [[ "$SEGSIZE" == "seq" ]]; then
        # 1024 is the default segment size (assuming it's used in seq)
        #SEGSIZE=$(grep restore_backup_reads $d/out1.txt | tail -n 1 | awk '{ print $2 * 1024 }')
        SEGSIZE=1024
        TITLE="SEQ"
    fi

    for s in $SIMPLE_STATS; do
        grep "$s" $d/out1.txt |
        awk -v segsize=$TITLE '{ if ($2 > 0) { print segsize, $2 } }' \
            >> "$s".txt
    done

    cat $d/agglog.txt |
    awk -v segsize=$SEGSIZE -v title=$TITLE \
        'BEGIN { cnt = 0; sum = 0; } 
         { sum += $2; cnt++; }
         END { printf("%s %d\n", title, (sum/cnt)*segsize*8/1024) }' \
        >> bandwidth.txt

    logvol=$(grep restore_log_volume $d/out1.txt | tail -n 1 | awk '{print $2}')
    # lareads=$(($LA_BLOCK_SIZE * 1024 * $(grep la_block_reads $d/out1.txt | tail -n 1 | awk '{print $2}')))
    lareads=$(grep la_read_volume $d/out1.txt | awk '{ print $2 }')
    echo $TITLE $(bc -l <<< "$lareads / $logvol") >> la_read_efficiency.txt

    echo $TITLE $(wc -l $d/agglog.txt) >> total_times.txt

    cat $d/iostat.txt |
    awk -v segsize=$SEGSIZE -v arch=$ARCH_DEV -v db=$DB_DEV -v backup=$BACKUP_DEV \
        'BEGIN { track = 0; }
         { if (track == 3) { print a, b, c; track = 0 } }
         $1 == arch { a = $6; track++ }
         $1 == backup { b = $6; track++ }
         $1 == db { c = $7; track++}' \
        > iostat_"$TITLE".txt

    # GENERATE PER_SEGMENT PLOTS
    gnuplot -e "outfile='iostat_"$TITLE".png'; file='iostat_"$TITLE".txt'; segsize="$SEGSIZE"" iostat.gp
done

for f in $CALC_STATS $SIMPLE_STATS; do
    sortfile $f.txt;

    # GENERATE GLOBAL PLOTS
    gnuplot -e "outfile='"$f".png'; file='"$f".txt'" bars.gp
done

gnuplot restore_times.gp
