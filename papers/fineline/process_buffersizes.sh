#!/bin/bash

EXPDIR=$1
PLOTDIR=gnuplot

LOG_DEV=sda
ARCH_DEV=sdg
DB_DEV=sdh

if [ -z "$EXPDIR" ]; then
    echo "Missing argument: exp dir"
    exit 1
fi

function pdfcompile()
{
    pdflatex -halt-on-error $1 1> pdflatex.txt 2>&1
}

STATS=""
# TSERIES="buffersizes evict_time"

# Size of window when applying moving average
MAVG_WINDOW=10
THREADS=12
CHKPT_FREQ=5

for s in $STATS; do
    rm -f $EXPDIR/$s.txt
done
for s in $TSERIES; do
    rm -f $EXPDIR/$s.txt
    touch $EXPDIR/$s.txt
done
rm -f pdflatex.txt

COUNT=0

for d in $EXPDIR/buffersizes-*; do
    d=$(basename $d)
    BUFSIZE=${d#buffersizes-}
    DIR=$EXPDIR/$d
    COUNT=$((COUNT + 1))

    if [ -f $DIR/iostat.txt ]; then
        cat $DIR/iostat.txt |
        awk -v archdev=$ARCH_DEV -v logdev=$LOG_DEV -v dbdev=$DB_DEV \
            'BEGIN { track = 0; }
             { if (track == 6) { print a, b, c, d, e, f; track = 0 } }
             $1 == dbdev { e = $7; track++ }
             $1 == dbdev { f = $6; track++ }
             $1 == archdev { c = $7; track++ }
             $1 == archdev { d = $6; track++ }
             $1 == logdev { a = $7; track++}
             $1 == logdev { b = $6; track++}' \
            > $DIR/iostat_dev.txt
    fi

    if [ -f $DIR/iostat.txt ]; then
        cat $DIR/iostat.txt |
        awk -v archdev=$ARCH_DEV -v logdev=$LOG_DEV -v dbdev=$DB_DEV \
            'BEGIN { track = 0; }
             { if (track == 6) { print a, b, c, d, e, f; track = 0 } }
             $1 == dbdev { e = $5; track++ }
             $1 == dbdev { f = $4; track++ }
             $1 == archdev { c = $5; track++ }
             $1 == archdev { d = $4; track++ }
             $1 == logdev { a = $5; track++}
             $1 == logdev { b = $4; track++}' \
            > $DIR/iops_dev.txt
    fi

    if [ -f $DIR/propstats_chkpt.txt ]; then
        awk -v freq=$CHKPT_FREQ '
        {
            for (i=0; i<freq; i++) {
                if ($2 > 0) { print $0 }
            }
        }' \
        $DIR/propstats_chkpt.txt > $DIR/propstats_chkpt_ext.txt
    fi

#     if [ -f $DIR/out1.txt ]; then
#         HITS=$(awk '$1 == "bf_hit_cnt" { print $2; exit }' $DIR/out1.txt)
#         FIXES=$(awk '$1 == "bf_fix_cnt" { print $2; exit }' $DIR/out1.txt)
#         if [ $FIXES -gt 0 ]; then
#             bc -l <<< "$HITS / $FIXES"  > $DIR/hit_ratio.txt
#         fi
#     fi

    awk -v window=$MAVG_WINDOW '
        BEGIN { passed = 0; }
        substr($0,0,1) == "#" { print $0; next }
        !passed && $4 == 0 { next }
        {
            nr++
            n = window
            for (i = 0; i < n-1; i++) {
                t[i] = t[i+1]
            }
            t[n-1] = $4
            sum_t = 0
            for (i = 0; i < n; i++) {
                sum_t += t[i]
            }
            div = nr > window ? window : nr;
            print $1, $2, $3, sum_t/div, $5, $6
        }' \
        $DIR/propstats.txt > $DIR/propstats_ext.txt

    if [ -f $DIR/tput.txt ]; then
        mv $DIR/tput.txt $DIR/agglog.txt
    fi

    awk -v bufsize=$BUFSIZE -v window=$MAVG_WINDOW '
         BEGIN { print bufsize/1000 " GB" }
         {
            n = window
            for (i = 0; i < n-1; i++) {
                t[i] = t[i+1]
            }
            t[n-1] = $1
            sum_t = 0
            for (i = 0; i < n; i++) {
                sum_t += t[i]
            }

            div = (NR > window ? window : NR);
            print sum_t/div
        }' \
        $DIR/agglog.txt > $DIR/agglog_smooth.txt

    awk -v bufsize=$BUFSIZE -v window=$MAVG_WINDOW '
         BEGIN { print bufsize/1000 " GB" }
         {
            n = window
            for (i = 0; i < n-1; i++) {
                t[i] = t[i+1]
            }
            t[n-1] = $1
            sum_t = 0
            for (i = 0; i < n; i++) {
                sum_t += t[i]
            }

            div = (NR > window ? window : NR);
            print sum_t/div
        }' \
        $DIR/evict_time.txt > $DIR/evict_time_smooth.txt

#     paste $DIR/agglog_smooth.txt $EXPDIR/buffersizes.txt > $EXPDIR/tmp.txt
#     mv $EXPDIR/tmp.txt $EXPDIR/buffersizes.txt

#     paste $DIR/evict_time_smooth.txt $EXPDIR/evict_time.txt > $EXPDIR/tmp.txt
#     mv $EXPDIR/tmp.txt $EXPDIR/evict_time.txt

    gnuplot -e "dir='"$DIR"'; bufsize="$BUFSIZE"; threads=$THREADS" \
        evict_time.gp

    gnuplot -e "dir='"$DIR"'; bufsize="$BUFSIZE"" \
        iostat.gp

    gnuplot -e "dir='"$DIR"'; bufsize='"$BUFSIZE"';" \
        iops.gp

    gnuplot -e "dir='"$DIR"'; bufsize='"$BUFSIZE"';" \
        backlog.gp

    SPWRITES=$(awk '$1=="1" { print $2; exit }' $DIR/writesizes.txt)
    if [ -z "$SPWRITES" ]; then SPWRITES=1; fi
    gnuplot -e "dir='"$DIR"'; spwrites=$SPWRITES; bufsize='"$BUFSIZE"';" \
        writesizes.gp

    pdfcompile iostat_"$BUFSIZE"
    pdfcompile iops_"$BUFSIZE"
    pdfcompile evict_time_"$BUFSIZE"
    pdfcompile backlog_"$BUFSIZE"
    pdfcompile writesizes_"$BUFSIZE"

    rm -f *.aux *.log *-inc.pdf *.tex
done

for s in $STATS; do
    sort -n $EXPDIR/$s.txt > tmp.txt
    mv tmp.txt $EXPDIR/$s.txt
done

# if [ $COUNT -gt 0 ]; then
#     # Replace empty columns with ?, so that gnuplot processes them correctly
#     sed -i -e 's/\t\t/\t?\t/g' -e 's/\t\t/\t?\t/g' -e 's/^\t/?\t/g' $EXPDIR/buffersizes.txt

#     NCOLUMNS=$(awk 'NR==2 {print NF}' $EXPDIR/buffersizes.txt)
#     echo NCOLUMNS=$NCOLUMNS
#     gnuplot -e "dir='"$EXPDIR"'; ncolumns="$NCOLUMNS";" buffersizes.gp
#     pdfcompile buffersizes

#     gnuplot -e "dir='"$EXPDIR"'; ncolumns="$NCOLUMNS";" evict_time.gp
#     pdfcompile evict_time

#     rm -f *.aux *.log *-inc.pdf *.tex
#     # pdfunite tput_*.pdf bandwidth_*.pdf \
#     #     losses.pdf bandwidth.pdf xctlatency.pdf xctlatency_distr.pdf tput_all.pdf 1> /dev/null 2>&1
# fi

mv *.pdf $EXPDIR/
mv *.txt $EXPDIR/
