set terminal cairolatex standalone pdf size 8.5cm,4cm dashed transparent font "default,9"
set output "xctlatency_distr.tex"
set datafile separator "\t"

set style line 11 lc rgb '#808080' lt 1
set border 11 back ls 11
set style line 12 lc rgb '#999999' lt 0 lw 1
set grid back ls 12
set style line 1 lc rgb '#8b1a0e' lt 1 lw 3 pt 7 ps 1 #red
set style line 2 lc rgb '#0c119c' lt 1 lw 2 pt 7 ps 1 #blue
set style line 3 lc rgb '#5e9c36' lt 1 lw 2 pt 13 ps 1 #green
set style line 4 lc rgb '#303030' lt 1 lw 3 pt 13 ps 1 #darkgrey
set style fill transparent solid 0.5 border

set lmargin 8
set rmargin 1

set auto x
unset xtics
set xtics nomirror scale 0 font ",8"
set xrange [-0.5:(ncolumns-0.5)]
set xlabel "Segment size (KB)"

set style fill empty
set boxwidth 0.5
set style data candlesticks 
unset mytics
set logscale y
set format y "$10^{%L}$"
set ylabel "Latency (sec)"

# x min 1st mean 2nd max
plot dir."/xctlatency_distr.txt" using (column(0)):3:2:6:5:xtic(1) ls 4 notitle whiskerbars, \
   "" using (column(0)):($6 + 0.9*$6):(sprintf("%.3fs", $6)) with labels notitle
