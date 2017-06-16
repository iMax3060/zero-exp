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
TSERIES="xctlatency xctlatency_distr bandwidth_lines"
SEGSIZE=4096

# Size of window when applying moving average
MAVG_WINDOW=5
# How many seconds before failure to use in avg. pre-failure throughput calculation
PRE_FAILURE_WINDOW=60

for s in $STATS; do
    rm -f $EXPDIR/$s.txt
done
for s in $TSERIES; do
    rm -f $EXPDIR/$s.txt
done
rm -f pdflatex.txt

COUNT=0

for d in $EXPDIR/restore-*; do
    d=$(basename $d)
    BUFSIZE=${d#restore-}
    BUFSIZE=$((BUFSIZE / 1000))
    DIR=$EXPDIR/$d
    COUNT=$((COUNT + 1))

    # expected columns of agglog.txt:
    # xct_end restore_begin restore_segment restore_end page_write page_read 
    awk -v prefw=$PRE_FAILURE_WINDOW '
        BEGIN { passed = 0; in_recovery = 0; j = 0; pre_failure = 0 }
        NR > 1 && ($1 + $2 + $5 > 0 || in_recovery) {
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
    # expected columns of agglog_ext.txt:
    # xct_end restore_begin restore_segment restore_end pre_failure page_write page_read xct_loss
    awk -v window=$MAVG_WINDOW '
         {
            n = window
            for (i = 0; i < n-1; i++) {
                t[i] = t[i+1]
                r[i] = r[i+1]
                b[i] = b[i+1]
            }
            t[n-1] = $1
            r[n-1] = $7
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
            print sum_t/div, $2, sum_b/div, $4, $5, $6, sum_r/div, $8
        }' \
        $DIR/agglog_ext.txt > $DIR/agglog_smooth.txt

    # extract recovery begin and end on X axis
    RBEGIN=$(awk '$2 > 0 { print NR; exit }' $DIR/agglog_ext.txt)
    REND=$(awk '$4 > 0 { print NR; exit }' $DIR/agglog_ext.txt)

    cat $DIR/agglog_smooth.txt |
    awk -v segsize=$SEGSIZE -v title=$BUFSIZE \
        'BEGIN {
            began = 0
            print title " GB"
         } 
         NR > 1 { 
             if ($4 > 0) { exit }
             if (!began) { began = $2 }
             if (began) { print $3 * segsize * 8 / 1024 }
         }' \
        > $DIR/bandwidth.txt

    # Combine bandwidth of this experiment with the others
    touch $EXPDIR/bandwidth_lines.txt
    paste $DIR/bandwidth.txt $EXPDIR/bandwidth_lines.txt > $EXPDIR/tmp.txt
    mv $EXPDIR/tmp.txt $EXPDIR/bandwidth_lines.txt

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

    if [ -f $DIR/iostat.txt ]; then
        cat $DIR/iostat.txt |
        awk -v arch=$ARCH_DEV -v db=$DB_DEV -v backup=$BACKUP_DEV \
            'BEGIN { track = 0; }
             { if (track == 4) { print a, b, c, d; track = 0 } }
             $1 == arch { a = $6; track++ }
             $1 == backup { b = $6; track++ }
             $1 == db { c = $7; track++}
             $1 == db { d = $6; track++}' \
            > $DIR/iostat_dev.txt
    fi

    awk -v v=$BUFSIZE '{ sum += $8 } END { print v,(sum > 0 ? sum : 0) }' \
        $DIR/agglog_smooth.txt >> $EXPDIR/losses.txt

    # Smooth-out xct latency output
    touch $EXPDIR/xctlatency.txt
    awk -v bufsize=$BUFSIZE -v window=$MAVG_WINDOW '
         BEGIN { print bufsize " GB" }
         $1 > 0 {
            n = window
            for (i = 0; i < n-1; i++) {
                t[i] = t[i+1]
            }
            t[n-1] = $1
            sum_t = 0
            for (i = 0; i < n; i++) {
                sum_t += t[i]
            }

            div = 1000000 * (NR > window ? window : NR);
            print sum_t/div
        }' \
        $DIR/xctlatency.txt > $DIR/xctlatency_smooth.txt

    # Combine latencies of this experiment with the others
    paste $DIR/xctlatency_smooth.txt $EXPDIR/xctlatency.txt > $EXPDIR/tmp.txt
    mv $EXPDIR/tmp.txt $EXPDIR/xctlatency.txt

    # Print latency distribution during restore, without smoothing
    awk -v rbegin=$RBEGIN -v rend=$REND -v bufsize=$BUFSIZE '
        function round(x) {
            return int(x + 0.5)
        }
        BEGIN { i = 1; f[i] = 0; started = 0 }
        NR >= rbegin && NR <= rend && (started || $1 > 0) {
            if ($1 > 0) {
                started = 1
                # get from nsec to sec
                f[i] += $1 / 1000000000
                i += 1
                if (NR < rend) { f[i] = 0 }
            }
            else {
                # a tick with value zero means no txn committed in that second
                f[i] += 1
            }
        }
        END {
            # sort the array
            n = asort(f);
            # get quartile indices
            q1ix = round(n/4);
            q2ix = round(n/2);
            q3ix = round(3 * n/4);
            # get quartile values
            min = f[1];
            max = f[n];
            for (i = 1; i <= n; i += 1) {
                if (i == q1ix) q1 = f[i];
                if (i == q2ix) q2 = f[i];
                if (i == q3ix) q3 = f[i];
            }
            # print quartiles
            printf "%s\t%.8f\t%.8f\t%.8f\t%.8f\t%.8f\n", \
                bufsize " GB", min, q1, q2, q3, max
        
        }' $DIR/xctlatency.txt >> $EXPDIR/xctlatency_distr.txt

    ## Little hack to get lower yrange for small buffer
    YMAX=14
    # if [ $BUFSIZE -le 10 ]; then
    #     YMAX=2
    # fi

    echo RBEGIN=$RBEGIN, REND=$REND

    gnuplot -e "dir='"$DIR"'; bufsize="$BUFSIZE"; rbegin="$RBEGIN"; rend="$REND"; ymax="$YMAX";" \
        tput_restore.gp

    gnuplot -e "dir='"$EXPDIR"/"$d"'; bufsize="$BUFSIZE";" \
        bandwidth_restore.gp

    gnuplot -e "dir='"$EXPDIR"/"$d"'; bufsize="$BUFSIZE";" \
        tracerestore.gp

    gnuplot -e "dir='"$EXPDIR"/"$d"'; bufsize="$BUFSIZE";" \
        tput_accum.gp

    gnuplot -e "dir='"$EXPDIR"/"$d"'; bufsize="$BUFSIZE"" \
        iostat.gp

    pdfcompile tput_"$BUFSIZE"
    pdfcompile bandwidth_"$BUFSIZE"
    pdfcompile accum_"$BUFSIZE"
    pdfcompile tracerestore_"$BUFSIZE"
    pdfcompile iostat_"$BUFSIZE"
done

for s in $STATS; do
    sort -n $EXPDIR/$s.txt > tmp.txt
    mv tmp.txt $EXPDIR/$s.txt
done

if [ $COUNT -gt 1 ]; then
    gnuplot -e "dir='"$EXPDIR"'" losses.gp
    gnuplot -e "dir='"$EXPDIR"'" bandwidth.gp

    # Replace empty columns with ?, so that gnuplot processes them correctly
    sed -i -e 's/\t\t/\t?\t/g' -e 's/\t\t/\t?\t/g' -e 's/^\t/?\t/g' $EXPDIR/xctlatency.txt
    sed -i -e 's/\t\t/\t?\t/g' -e 's/\t\t/\t?\t/g' -e 's/^\t/?\t/g' $EXPDIR/bandwidth_lines.txt

    NCOLUMNS=$(awk 'NR==2 {print NF}' $EXPDIR/xctlatency.txt)
    echo NCOLUMNS=$NCOLUMNS
    gnuplot -e "dir='"$EXPDIR"'; ncolumns="$NCOLUMNS";" xctlatency.gp
    gnuplot -e "dir='"$EXPDIR"'; ncolumns="$NCOLUMNS";" xctlatency_distr.gp
    gnuplot -e "dir='"$EXPDIR"'; ncolumns="$NCOLUMNS";" bandwidth_lines.gp

    pdfcompile losses
    pdfcompile bandwidth
    pdfcompile xctlatency
    pdfcompile xctlatency_distr
    pdfcompile bandwidth_lines
    pdfcompile key

    pdfcrop key.pdf key.pdf > /dev/null

    rm -f *.aux *.log *-inc.pdf *.tex
    pdfunite tput_*.pdf bandwidth_*.pdf \
        losses.pdf bandwidth.pdf xctlatency.pdf xctlatency_distr.pdf tput_all.pdf 1> /dev/null 2>&1
fi

mv *.pdf $EXPDIR/
mv *.txt $EXPDIR/
