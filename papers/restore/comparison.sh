#!/bin/bash
DIR1=$1
DIR2=$2
DIR3=$3

if [ -z "$DIR1" ]; then
    echo "Missing argument: exp dir"
    exit 1
fi

if [ -z "$DIR2" ]; then
    echo "Missing argument: exp dir"
    exit 1
fi

if [ -z "$DIR3" ]; then
    echo "Missing argument: exp dir"
    exit 1
fi

MAVG_WINDOW=50

function pdfcompile()
{
    pdflatex -halt-on-error $1 1> pdflatex.txt 2>&1
}

AWK_SCRIPT='BEGIN { started = 0 }
NR > 1 {
    n = window
    if (spr && (NR >= rbegin && NR < rend)) {
        print 0, $2, $3, $4
        next
    }
    if (drop && (NR == rbegin)) {
        for (i = 0; i < n; i++) {
            t[i] = 0
        }
    }
    else {
        for (i = 0; i < n-1; i++) {
            t[i] = t[i+1]
        }
    }
    t[n-1] = $1
    sum_t = 0
    for (i = 0; i < n; i++) {
        sum_t += t[i]
    }

    div = NR > window ? window : NR;
    if (spr && NR > rend && NR - rend < window) {
        #div = NR - rend + 1
    }
    else if (drop && (NR == rbegin)) {
        div = 1
    }
    print sum_t/div, $2, $3, $4
}'

RBEGIN=$(awk '$2 > 0 { print NR; exit }' $DIR1/agglog_ext.txt)
REND=$(awk '$4 > 0 { print NR; exit }' $DIR1/agglog_ext.txt)

echo rbegin=$RBEGIN rend=$REND

awk -v window=$MAVG_WINDOW -v spr="1" -v drop="1" -v rbegin=$RBEGIN -v rend=$REND "$AWK_SCRIPT" \
    $DIR1/agglog_ext.txt > $DIR1/agglog_super_smooth.txt

awk -v window=$MAVG_WINDOW -v spr="0" -v drop="1" -v rbegin=$RBEGIN -v rend=$REND "$AWK_SCRIPT" \
    $DIR2/agglog_ext.txt > $DIR2/agglog_super_smooth.txt

awk -v window=$MAVG_WINDOW -v spr="0" -v drop="0" -v rbegin=$RBEGIN -v rend=$REND "$AWK_SCRIPT" \
    $DIR3/agglog_ext.txt > $DIR3/agglog_super_smooth.txt

gnuplot -e "dir1='"$DIR1"'; dir2='"$DIR2"'; dir3='"$DIR3"'; rbegin="$RBEGIN"; rend="$REND";" tput_simple.gp

pdfcompile tput_simple
rm -f *.aux *.log *-inc.pdf *.tex
