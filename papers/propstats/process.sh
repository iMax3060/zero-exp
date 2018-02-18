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

# Size of window when applying moving average
MAVG_WINDOW=20
# How many seconds before failure to use in avg. pre-failure throughput calculation
PRE_FAILURE_WINDOW=60

EXPNAME=buffersizes

STATS="avg_write_bwidth"

for s in $STATS; do
    rm -f $EXPDIR/$s.txt
done
rm -f pdflatex.txt

for d in $EXPDIR/buffersizes-*; do
    d=$(basename $d)
    # BUFSIZE=${d#buffersizes-}
    DIR=$EXPDIR/$d
    [ -d $DIR ] || continue;

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

    echo -n $(tr '_' '-' <<< $d)" " >> $EXPDIR/avg_write_bwidth.txt
    awk '{ sum+=$3; cnt++; } END { print sum/cnt }' $DIR/propstats_ext.txt\
        >> $EXPDIR/avg_write_bwidth.txt

    gnuplot -e "dir='"$DIR"';" backlog.gp
    pdfcompile backlog
    mv backlog.pdf $DIR/
done

# sort -n -k2 $EXPDIR/avg_write_bwidth.txt > tmp.txt
# mv tmp.txt $EXPDIR/avg_write_bwidth.txt
# gnuplot -e "dir='"$EXPDIR"'" wbandwidth.gp
# pdfcompile wbandwidth

# LIST="mixed_200k oldest_200k clustered_8 log_based"

# gnuplot -e "dir='"$EXPDIR"'; list='$LIST'" lines.gp
# pdfcompile lines
# mv lines.pdf backlog.pdf

# pdfcompile key
# pdfcrop key.pdf key.pdf

rm -f *.aux *.log *-inc.pdf *.tex
# pdfunite $EXPDIR/*/backlog.pdf $EXPDIR/backlog_all.pdf \
#     1> /dev/null 2>&1

# mv *.pdf $EXPDIR/
# mv *.txt $EXPDIR/

