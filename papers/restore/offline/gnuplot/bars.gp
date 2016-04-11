set terminal pngcairo dashed size 700,400
set output outfile

set style line 11 lc rgb '#808080' lt 1
set border 11 back ls 11
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12
set style line 1 lc rgb '#8b1a0e' lt 1 lw 1 pt 7 ps 1 #red
set style line 2 lc rgb '#0c119c' lt 1 lw 1 pt 6 ps 1 #blue
set style line 3 lc rgb '#5e9c36' lt 1 lw 1 pt 13 ps 1 #green
set style fill transparent solid 0.2 border

set lmargin 8
set rmargin 1

set key top right
set key outside

# set xtics mirror 20,20
unset xtics
set xtics nomirror
set xtics rotate by -45
set xlabel "Segment size"

# set ytics 10,20 nomirror
# set yrange [0:90]
# set ylabel "Bandwidth (MB/s)"
# set format y "%.0s"
unset mytics

set boxwidth 0.7

plot file using (column(0)):2:xtic(1) with boxes ls 2 t ""
