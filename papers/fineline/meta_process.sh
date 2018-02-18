#!/bin/bash

BASEDIR=~/work/zero-results/warmup_db
REP_PREFIX=rep16
PAPER_DIR=~/Dropbox/Work/Papers/Thesis/img/restart_skewed_ssd

COUNT=$(find $BASEDIR/$REP_PREFIX? -maxdepth 0 -type d | wc -l)

function pdfcompile()
{
    pdflatex -halt-on-error $1 1> pdflatex.txt 2>&1
}

mkdir -p $PAPER_DIR

rm -f $BASEDIR/txnmiss.txt
rm -f $BASEDIR/txndiff.txt

for i in `seq 0 $((COUNT-1))`; do
    if [ ! -z "$(ls -A $BASEDIR/$REP_PREFIX$i)" ]; then
        ./process_restart.sh $BASEDIR/$REP_PREFIX$i
    fi
done

gnuplot -e "dir='"$BASEDIR"'; ncols=$COUNT" txnmiss.gp
pdfcompile txnmiss
gnuplot -e "dir='"$BASEDIR"'; ncols=$COUNT" txndiff.gp
pdfcompile txndiff
rm -f *.aux *.log *-inc.pdf *.tex

mv *.pdf $PAPER_DIR/
mv $BASEDIR/*.pdf $PAPER_DIR/
