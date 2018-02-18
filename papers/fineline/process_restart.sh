#!/bin/bash

EXPDIR=$1
PLOTDIR=gnuplot

LOG_DEV=sdd
ARCH_DEV=sde
DB_DEV=sdf

if [ ! -d "$EXPDIR" ]; then
    echo "Directory not found: $EXPDIR"
    exit 1
fi

if [ -z "$EXPDIR" ]; then
    echo "Missing argument: exp dir"
    exit 1
fi

function pdfcompile()
{
    pdflatex -halt-on-error $1 1> pdflatex.txt 2>&1
}

function getstat()
{
    echo $(grep $2 $1/out1.txt | awk '{ print $2 }')
}

STATS="log_efficiency"
TSERIES="tput xctlatency"
EXPNAME="warmup_db"
# EXPNAME="buffersizes"

# Size of window when applying moving average
MAVG_WINDOW=10

for s in $STATS; do
    rm -f $EXPDIR/$s.txt
done
for s in $TSERIES; do
    rm -f $EXPDIR/$s.txt
done
rm -f pdflatex.txt

COUNT=0

for d in $EXPDIR/$EXPNAME-*; do
    d=$(basename $d)
    PARAM=${d#$EXPNAME-}
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
        awk -v archdev=$ARCH_DEV -v logdev=$LOG_DEV \
            'BEGIN { track = 0; }
             { if (track == 4) { print a, b, c, d; track = 0 } }
             $1 == archdev { a = $5; track++ }
             $1 == archdev { b = $4; track++ }
             $1 == logdev { c = $5; track++}
             $1 == logdev { d = $4; track++}' \
            > $DIR/iops_dev.txt
    fi

    TITLE=$PARAM
    if [ "$PARAM" == "logbased" ]; then
        TITLE="ARIES restart"
    elif [ "$PARAM" == "instant" ]; then
        TITLE="Instant restart"
    elif [ "$PARAM" == "sorted" ]; then
        TITLE="Part. log index"
    elif [ "$PARAM" == "cleaner" ]; then
        TITLE="Instant + background redo + cleaner"
    elif [ "$PARAM" == "pagepass" ]; then
        TITLE="Instant + background redo"
    else
        TITLE=$PARAM"t"
    fi

    touch $EXPDIR/tput.txt
    awk -v title="$TITLE" -v window=$MAVG_WINDOW '
         BEGIN { print title }
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

    # Smooth-out xct latency output
    touch $EXPDIR/xctlatency.txt
    awk -v title="$TITLE" -v window=$MAVG_WINDOW '
         BEGIN { print title }
         {
            n = window
            for (i = 0; i < n-1; i++) {
                t[i] = t[i+1]
            }
            if ($1 > 0) {
                t[n-1] = $1
            }
            else if (n == 1) {
                t[n-1] = 1000000 
            }
            else {
                t[n-1] = t[n-2] + 1000000
                t[n-1] = 0
            }
            sum_t = 0
            for (i = 0; i < n; i++) {
                sum_t += t[i]
            }

            div = 1000000 * (NR > window ? window : NR);
            print sum_t/div
        }' \
        $DIR/xctlatency.txt > $DIR/xctlatency_smooth.txt

    # echo `getstat $DIR restore_log_volume`
    # echo `getstat $DIR la_read_volume`

    # restoreVol=$(getstat $DIR restore_log_volume)
    # logReadVol=$(getstat $DIR la_read_volume)
    # if [ $logReadVol -gt 0 ]; then
    #     echo $PARAM $(bc -l <<< "$restoreVol / $logReadVol") >> $EXPDIR/log_efficiency.txt
    # else
    #     echo $PARAM 0 >> $EXPDIR/log_efficiency.txt
    # fi

    # Combine latencies of this experiment with the others
    paste $DIR/agglog_smooth.txt $EXPDIR/tput.txt > $EXPDIR/tmp.txt
    mv $EXPDIR/tmp.txt $EXPDIR/tput.txt

    # Combine latencies of this experiment with the others
    paste $DIR/xctlatency_smooth.txt $EXPDIR/xctlatency.txt > $EXPDIR/tmp.txt
    mv $EXPDIR/tmp.txt $EXPDIR/xctlatency.txt

    # gnuplot -e "dir='"$DIR"'; bufsize="$PARAM"; rbegin="$RBEGIN"; rend="$REND"; ymax="$YMAX";" \
    #     tput_restore.gp

    # gnuplot -e "dir='"$EXPDIR"/"$d"'; bufsize="$PARAM";" \
    #     bandwidth_restore.gp

    # gnuplot -e "dir='"$EXPDIR"/"$d"'; bufsize="$PARAM";" \
    #     tracerestore.gp

    # gnuplot -e "dir='"$EXPDIR"/"$d"'; bufsize="$PARAM";" \
    #     tput_accum.gp

    gnuplot -e "dir='"$DIR"'; bufsize='"$PARAM"';" \
        iostat.gp

    gnuplot -e "dir='"$DIR"'; bufsize='"$PARAM"';" \
        iops.gp

    # pdfcompile tput_"$PARAM"
    # pdfcompile bandwidth_"$PARAM"
    # pdfcompile accum_"$PARAM"
    # pdfcompile tracerestore_"$PARAM"
    pdfcompile iostat_"$PARAM"
    pdfcompile iops_"$PARAM"
done


# for s in $STATS; do
#     sort -n $EXPDIR/$s.txt > tmp.txt
#     mv tmp.txt $EXPDIR/$s.txt
# done

if [ $COUNT -gt 0 ]; then
    # Replace empty columns with ?, so that gnuplot processes them correctly
    # sed -i -e 's/\t\t/\t?\t/g' -e 's/\t\t/\t?\t/g' -e 's/^\t/?\t/g' $EXPDIR/tput.txt

    # trim columns to they have the same number of lines
    awk -v ncol=$COUNT '{ if (NR==1 || NF == ncol) {print $0}}' $EXPDIR/tput.txt > tmp.txt
    mv tmp.txt $EXPDIR/tput.txt
    awk -v ncol=$COUNT '{ if (NR==1 ||NF == ncol) {print $0}}' $EXPDIR/xctlatency.txt > tmp.txt
    mv tmp.txt $EXPDIR/xctlatency.txt

    NCOLUMNS=$(awk 'NR==2 {print NF}' $EXPDIR/tput.txt)
    echo NCOLUMNS=$NCOLUMNS
    gnuplot -e "dir='"$EXPDIR"'; ncolumns="$NCOLUMNS";" tput.gp

    # Dirty hack: directory for 8 GB log is rep*3
    if [ -f $EXPDIR/redo_len.txt ]; then
        REDO_LEN=$(cat $EXPDIR/redo_len.txt)
    else
        REPDIR=`basename $EXPDIR`
        REDO_LEN=$((1 << (${REPDIR:3} % 10)))
    fi

    # LA_END=$(awk 'NR>1 && $2>0{ print NR-1; exit }' $EXPDIR/tput.txt)
    TXN_DIFF=0
    # TXN_DIFF=$(awk 'NR<420{ s1+=$1; s2+=$2 } END { print s2-s1 }' $EXPDIR/tput.txt)
    gnuplot -e "dir='"$EXPDIR"'; redolen="$REDO_LEN"; txndiff="$TXN_DIFF";" instantrestart.gp

    # gnuplot -e "dir='"$EXPDIR"'; redolen="$REDO_LEN"; ncolumns="$NCOLUMNS";" xctlatency.gp

    # output rep data into extra file for txndiffs
    # echo $REDO_LEN $TXN_DIFF >> $EXPDIR/../txndiff.txt

    # ARIES_MAX=$(tail -n 60 $EXPDIR/tput.txt | awk '{s+=$1}END{print s/NR}')
    # INSTANT_MAX=$(tail -n 60 $EXPDIR/tput.txt | awk '{s+=$2}END{print s/60}')

    # Hack: maxes can vary from one experiment to another, so ideally we should
    # get the max over all experiments, which would require another pass. To
    # simplify this for now, just use constant value
    INSTANT_MAX=30000

    # head -n 720 $EXPDIR/tput.txt \
    cat $EXPDIR/tput.txt \
    | awk -v amax=$INSTANT_MAX -v imax=$INSTANT_MAX -v prefix=$REDO_LEN \
        'NR>1 { s1 += (amax-$1); s2 += (imax-$2);} END { print prefix, s1, s2, s1-s2 }' \
        >> $EXPDIR/../txnmiss.txt

    # use script below to compare 3 data series
        # 'NR>1 { s1 += (amax-$1); s2 += (imax-$2); s3 += (imax-$3)} END { print prefix, s1, s2, s3, s1-s2 }' \

    # FIRST_TXN=$(awk 'NR>1 && $1>0{print NR; exit}' $EXPDIR/tput.txt)
    # gnuplot -e "dir='"$EXPDIR"'; fnum=1; yend=0.4; xbegin=0; xend=15" instantrestart_zoom.gp
    # gnuplot -e "dir='"$EXPDIR"'; fnum=2; yend=0.4; xbegin=$((FIRST_TXN-5)); xend=$((FIRST_TXN+10))" instantrestart_zoom.gp
    # gnuplot -e "dir='"$EXPDIR"'; fnum=3; yend=10; xbegin=42; xend=57" instantrestart_zoom.gp

    # pdfcompile tput
    # pdfcompile xctlatency
    pdfcompile instantrestart
    # pdfcompile instantrestart_zoom1
    # pdfcompile instantrestart_zoom2
    # pdfcompile instantrestart_zoom3

    # cp xctlatency.pdf $EXPDIR/../xctlatency_$REDO_LEN.pdf
    # mv xctlatency.pdf xctlatency_$REDO_LEN.pdf
    cp instantrestart.pdf $EXPDIR/../instantrestart_$REDO_LEN.pdf
    mv instantrestart.pdf instantrestart_$REDO_LEN.pdf
    # mv instantrestart_zoom1.pdf $EXPDIR/../instantrestart_"$REDO_LEN"_zoom1.pdf
    # mv instantrestart_zoom2.pdf $EXPDIR/../instantrestart_"$REDO_LEN"_zoom2.pdf

#     pdfcompile key
#     pdfcrop key.pdf key.pdf > /dev/null
#     mv key.pdf restart_key_cleaner.pdf

    # rm -f *.aux *.log *-inc.pdf *.tex
    # pdfunite tput_*.pdf bandwidth_*.pdf \
    #     losses.pdf bandwidth.pdf xctlatency.pdf xctlatency_distr.pdf tput_all.pdf 1> /dev/null 2>&1
fi

mv *.pdf $EXPDIR/
mv *.txt $EXPDIR/
