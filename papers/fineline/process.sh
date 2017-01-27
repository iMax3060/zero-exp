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

STATS=""
TSERIES="buffersizes"

# Size of window when applying moving average
MAVG_WINDOW=60

for s in $STATS; do
    rm -f $EXPDIR/$s.txt
done
for s in $TSERIES; do
    rm -f $EXPDIR/$s.txt
done
rm -f pdflatex.txt

COUNT=0

for d in $EXPDIR/db-*; do
    d=$(basename $d)
    BUFSIZE=${d#db-}
    DIR=$EXPDIR/$d
    COUNT=$((COUNT + 1))

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

    touch $EXPDIR/buffersizes.txt
    awk -v bufsize=$BUFSIZE -v window=$MAVG_WINDOW '
         BEGIN { print bufsize " MB" }
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

            div = (NR > window ? window : NR);
            print sum_t/div
        }' \
        $DIR/agglog.txt > $DIR/agglog_smooth.txt

    # Combine latencies of this experiment with the others
    paste $DIR/agglog_smooth.txt $EXPDIR/buffersizes.txt > $EXPDIR/tmp.txt
    mv $EXPDIR/tmp.txt $EXPDIR/buffersizes.txt

    # gnuplot -e "dir='"$DIR"'; bufsize="$BUFSIZE"; rbegin="$RBEGIN"; rend="$REND"; ymax="$YMAX";" \
    #     tput_restore.gp

    # gnuplot -e "dir='"$EXPDIR"/"$d"'; bufsize="$BUFSIZE";" \
    #     bandwidth_restore.gp

    # gnuplot -e "dir='"$EXPDIR"/"$d"'; bufsize="$BUFSIZE";" \
    #     tracerestore.gp

    # gnuplot -e "dir='"$EXPDIR"/"$d"'; bufsize="$BUFSIZE";" \
    #     tput_accum.gp

    # gnuplot -e "dir='"$EXPDIR"/"$d"'; bufsize="$BUFSIZE"" \
    #     iostat.gp

    # pdfcompile tput_"$BUFSIZE"
    # pdfcompile bandwidth_"$BUFSIZE"
    # pdfcompile accum_"$BUFSIZE"
    # pdfcompile tracerestore_"$BUFSIZE"
    # pdfcompile iostat_"$BUFSIZE"
done

for s in $STATS; do
    sort -n $EXPDIR/$s.txt > tmp.txt
    mv tmp.txt $EXPDIR/$s.txt
done

if [ $COUNT -gt 1 ]; then
    # Replace empty columns with ?, so that gnuplot processes them correctly
    sed -i -e 's/\t\t/\t?\t/g' -e 's/\t\t/\t?\t/g' -e 's/^\t/?\t/g' $EXPDIR/buffersizes.txt

    NCOLUMNS=$(awk 'NR==2 {print NF}' $EXPDIR/buffersizes.txt)
    echo NCOLUMNS=$NCOLUMNS
    gnuplot -e "dir='"$EXPDIR"'; ncolumns="$NCOLUMNS";" buffersizes.gp

    # pdfcompile buffersizes
    # rm -f *.aux *.log *-inc.pdf *.tex
    # pdfunite tput_*.pdf bandwidth_*.pdf \
    #     losses.pdf bandwidth.pdf xctlatency.pdf xctlatency_distr.pdf tput_all.pdf 1> /dev/null 2>&1
fi

mv *.pdf $EXPDIR/
mv *.txt $EXPDIR/
