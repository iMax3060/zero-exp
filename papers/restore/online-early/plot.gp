set terminal pngcairo dashed
set output "plot.png"

set style line 11 lc rgb '#808080' lt 1
set border 3 back ls 11
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12
set style line 1 lc rgb '#8b1a0e' lt 1 lw 2 pt 7 ps 1 #red
set style line 2 lc rgb '#0c119c' lt 1 lw 1 pt 6 ps 1 #blue
set style line 3 lc rgb '#5e9c36' lt 1 lw 1 pt 13 ps 1 #green
set style fill transparent solid 0.2 border

set multiplot layout 2,1
set lmargin 8
set rmargin 1

set bmargin at screen 0.3
set tmargin at screen 0.98

set key left top

# FIRST PLOT (Throughput)
set size 0.90,0.6
set xtics mirror 30,30 format " "
set ytics 10,10 nomirror
set yrange [0:90]
set ylabel "Transactions/sec"
set format y "%.0s"
set y2tics 10,10 nomirror
set y2label "Page evictions/sec"
set format y2 "%.0s"
unset mytics

plot file using (column(0)):($1/1) with linespoints ls 1 t "Throughput", \
    "" using (column(0)):($5 > 0 ? ($5/1) : (1/0)) with linespoints ls  2 t "Page evictions"

set key at 170,1.3  opaque reverse width -3

set bmargin 4
set tmargin 0
# SECOND PLOT (Page read/write)
set size 0.9,0.3
set xtics nomirror 30,30 format "%.0f"
set xlabel "Time (seconds)"

set ytics format ""
set ylabel "Restore"
set yrange [0.5:1.5]
set y2tics format ""
set y2label ""

plot file using (column(0)):3 with points ls 3 t "Segment", \
   "" using (column(0)):2 with points ls 1 t "Begin/End", \
   "" using (column(0)):4 with points ls 1 t ""

