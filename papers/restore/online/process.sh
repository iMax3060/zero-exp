#!/bin/bash

EXPDIR=$1
PLOTDIR=gnuplot

ARCH_DEV=sdg
DB_DEV=sdh
BACKUP_DEV=sdi

if [ -z "$EXPDIR" ]; then
    echo "Missing argument: exp dir"
    exit 1
fi

function pdfcompile()
{
    pdflatex -halt-on-error $1 1> pdflatex.txt 2>&1
}

STATS="losses bandwidth"
SEGSIZE=4096

# Size of window when applying moving average
MAVG_WINDOW=20
# How many seconds before failure to use in avg. pre-failure throughput calculation
PRE_FAILURE_WINDOW=60

for s in $STATS; do
    rm -f $EXPDIR/$s.txt
done
rm -f pdflatex.txt

for d in $EXPDIR/restore-*; do
    d=$(basename $d)
    BUFSIZE=${d#restore-}
    BUFSIZE=$((BUFSIZE / 1000))
    DIR=$EXPDIR/$d

    awk -v prefw=$PRE_FAILURE_WINDOW '
        BEGIN { passed = 0; in_recovery = 0; j = 0; pre_failure = 0 }
        NR > 0 && $1+$2+$3+$4+$5 > 0 {
            if ($2 > 0) { in_recovery = 1 }
            if ($4 > 0) { in_recovery = 0 }

            loss = 0
            if (!passed) {
                t[j] = $1
                passed = $2
                print $1, $2, $3, $4, 0, $5, $6, loss

                j++
                if (j >= prefw) {
                    j = 0;
                }
            }
            else {
                if (pre_failure == 0) {
                    for (i = 0; i < prefw; i++) {
                        sum += t[i]
                    }
                    pre_failure = sum / prefw;
                }
                if (in_recovery) {
                    loss = pre_failure - $1
                }
                print $1, $2, $3, $4, pre_failure, $5, $6, loss
            }
        }' \
        $DIR/agglog.txt > $DIR/agglog_ext.txt

    awk '
        BEGIN { passed = 0 }
        {
            if (!passed) { passed = $2; skip; }
            acc += $1;
            print acc, $5, $6
        }' \
        $DIR/agglog.txt > $DIR/agglog_accum.txt

    # Smooth out both transaction throughput and page reads with moving average
    awk -v window=$MAVG_WINDOW '
         {
            n = window
            for (i = 0; i < n-1; i++) {
                t[i] = t[i+1]
                r[i] = r[i+1]
                b[i] = b[i+1]
            }
            t[n-1] = $1
            r[n-1] = $6
            b[n-1] = $3
            sum_t = 0
            sum_r = 0
            sum_b = 0
            for (i = 0; i < n; i++) {
                sum_t += t[i]
                sum_r += r[i]
                sum_b += b[i]
            }

            div = NR > window ? window : NR;
            print sum_t/div, $2, sum_b/div, $4, $5, sum_r/div, $7, $8
        }' \
        $DIR/agglog_ext.txt > $DIR/agglog_smooth.txt

    # extract recovery begin and end on X axis
    RBEGIN=$(awk '$2 > 0 { print NR; exit }' $DIR/agglog_smooth.txt)
    REND=$(awk '$4 > 0 { print NR; exit }' $DIR/agglog_smooth.txt)

    cat $DIR/agglog_smooth.txt |
    awk -v segsize=$SEGSIZE -v title=$BUFSIZE \
        'BEGIN { began = 0 } 
         NR > 1 { 
             if ($4 > 0) { exit }
             if (!began) { began = $2 }
             if (began) { print $3 * segsize * 8 / 1024 }
         }' \
        > $DIR/bandwidth.txt

    cat $DIR/agglog.txt |
    awk -v segsize=$SEGSIZE -v title=$BUFSIZE \
        'BEGIN { cnt = 0; sum = 0; began = false; } 
         NR > 1 { 
             if (!began) { began = $2; }
             if (began) { sum += $3; cnt++; }
             if ($4 > 0) { began = 0; }
         }
         END { printf("%s %.2f\n", title, (sum/cnt)*segsize*8/1024) }' \
        >> $EXPDIR/bandwidth.txt

    # cat $DIR/iostat.txt |
    # awk -v arch=$ARCH_DEV -v db=$DB_DEV -v backup=$BACKUP_DEV \
    #     'BEGIN { track = 0; }
    #      { if (track == 4) { print a, b, c, d; track = 0 } }
    #      $1 == arch { a = $7; track++ }
    #      $1 == backup { b = $6; track++ }
    #      $1 == db { c = $7; track++}
    #      $1 == db { d = $6; track++}' \
    #     > $DIR/iostat_dev.txt

    awk -v v=$BUFSIZE '{ sum += $8 } END { print v,(sum > 0 ? sum : 0) }' \
        $DIR/agglog_smooth.txt >> $EXPDIR/losses.txt

    ## Little hack to get lower yrange for small buffer
    YMAX=14
    if [ $BUFSIZE -le 10 ]; then
        YMAX=2
    fi

    gnuplot -e "dir='"$EXPDIR"/"$d"'; bufsize="$BUFSIZE"; rbegin="$RBEGIN"; rend="$REND"; ymax="$YMAX";" \
        tput_restore.gp

    gnuplot -e "dir='"$EXPDIR"/"$d"'; bufsize="$BUFSIZE";" \
        bandwidth_restore.gp

    gnuplot -e "dir='"$EXPDIR"/"$d"'; bufsize="$BUFSIZE";" \
        tput_accum.gp

    # gnuplot -e "dir='"$EXPDIR"/"$d"'; bufsize="$BUFSIZE"" \
    #     iostat.gp

    pdfcompile tput_"$BUFSIZE"
    pdfcompile bandwidth_"$BUFSIZE"
    pdfcompile accum_"$BUFSIZE"
    # pdfcompile iostat_"$BUFSIZE"
done

for s in $STATS; do
    sort -n $EXPDIR/$s.txt > tmp.txt
    mv tmp.txt $EXPDIR/$s.txt
done

gnuplot -e "dir='"$EXPDIR"'" losses.gp
gnuplot -e "dir='"$EXPDIR"'" bandwidth.gp

pdfcompile losses
pdfcompile bandwidth
pdfcompile key

pdfcrop key.pdf key.pdf > /dev/null

rm -f *.aux *.log *-inc.pdf *.tex
pdfunite tput_*.pdf bandwidth_*.pdf \
    losses.pdf bandwidth.pdf tput_all.pdf 1> /dev/null 2>&1

mv *.pdf $EXPDIR/
mv *.txt $EXPDIR/
