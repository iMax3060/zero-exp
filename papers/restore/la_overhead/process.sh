#!/bin/bash

EXPDIR=$1

if [ -z "$EXPDIR" ]; then
    echo "Missing argument: exp dir"
    exit 1
fi

function pdfcompile()
{
    pdflatex -halt-on-error $1 1> pdflatex.txt 2>&1
}

AWK_SCRIPT='
        function round(x) {
            return int(x + 0.5)
        }
        BEGIN { i = 1; started = 0 }
        $1 > 0 { f[i] = $1 / 1000; i += 1 }
        END {
            # sort the array
            n = asort(f);
            # get quartile indices
            q1ix = round(n/4);
            q2ix = round(n/2);
            q3ix = round(3 * n/4);
            # get quartile values
            min = f[30];
            max = f[n];
            for (i = 1; i <= n; i += 1) {
                if (i == q1ix) q1 = f[i];
                if (i == q2ix) q2 = f[i];
                if (i == q3ix) q3 = f[i];
            }
            # print quartiles
            printf "%s\t%.8f\t%.8f\t%.8f\t%.8f\t%.8f\n", \
                expname, min, q1, q2, q3, max
        
        }'

AWK_MPSTAT='NR > 3 { print 1000*(100-$13) }'

rm -f $EXPDIR/la_overhead_1.txt
rm -f $EXPDIR/la_overhead_2.txt
rm -f $EXPDIR/cpu_util_1.txt

awk "$AWK_MPSTAT" $EXPDIR/Copy+SSD/mpstat.txt > $EXPDIR/Copy+SSD/mpstat_proc.txt
awk "$AWK_MPSTAT" $EXPDIR/Sort+SSD/mpstat.txt > $EXPDIR/Sort+SSD/mpstat_proc.txt

awk -v expname="Copy" "$AWK_SCRIPT" $EXPDIR/Copy+SSD/agglog.txt >> $EXPDIR/la_overhead_1.txt
awk -v expname="Sort" "$AWK_SCRIPT" $EXPDIR/Sort+SSD/agglog.txt >> $EXPDIR/la_overhead_1.txt
awk -v expname="Copy" "$AWK_SCRIPT" $EXPDIR/Copy+SSD/mpstat_proc.txt >> $EXPDIR/cpu_util_1.txt
awk -v expname="Sort" "$AWK_SCRIPT" $EXPDIR/Sort+SSD/mpstat_proc.txt >> $EXPDIR/cpu_util_1.txt
# awk -v expname="Copy" "$AWK_SCRIPT" $EXPDIR/Copy+RAM/agglog.txt >> $EXPDIR/la_overhead_2.txt
# awk -v expname="Sort" "$AWK_SCRIPT" $EXPDIR/Sort+RAM/agglog.txt >> $EXPDIR/la_overhead_2.txt

gnuplot -e "dir='"$EXPDIR"';" la_overhead.gp
pdfcompile la_overhead

rm -f *.aux *.log *-inc.pdf *.tex
mv *.pdf $EXPDIR/
mv *.txt $EXPDIR/
