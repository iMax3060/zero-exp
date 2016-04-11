#!/bin/bash

rm -f bandwidth.txt
rm -f blockreads.txt

ARCH_DEV=sdd
DB_DEV=sde
BACKUP_DEV=sdf

function sortfile() {
    sort -n -t 1 $1 > tmp.txt
    mv tmp.txt $1
}

for d in restore-*; do
    SEGSIZE=${d#restore-}

    cat $d/agglog.txt |
    awk -v segsize=$SEGSIZE \
        'BEGIN { cnt = 0; sum = 0; } 
         { sum += $2; cnt++; }
         END { printf("%d %d\n", segsize, (sum/cnt)*segsize*8/1024) }' \
        >> bandwidth.txt

    grep la_block_reads $d/out1.txt |
    awk -v segsize=$SEGSIZE '{ if ($2 > 0) { print segsize, $2 } }' \
        >> blockreads.txt

    cat $d/iostat.txt |
    awk -v segsize=$SEGSIZE -v arch=$ARCH_DEV -v db=$DB_DEV -v backup=$BACKUP_DEV \
        'BEGIN { track = 0; }
         { if (track == 3) { print a, b, c; track = 0 } }
         $1 == arch { a = $6; track++ }
         $1 == backup { b = $6; track++ }
         $1 == db { c = $7; track++}' \
        > iostat_"$SEGSIZE".txt

    # GENERATE PER_SEGMENT PLOTS
    gnuplot -e "outfile='iostat_"$SEGSIZE".png'; file='iostat_"$SEGSIZE".txt'; segsize="$SEGSIZE"" iostat.gp
done

for f in bandwidth blockreads; do
    sortfile $f.txt;

    # GENERATE GLOBAL PLOTS
    gnuplot -e "outfile='"$f".png'; file='"$f".txt'" bars.gp
done
