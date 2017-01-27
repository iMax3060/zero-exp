set terminal pngcairo dashed font "default,9"
set output "buffersizes.png"
set datafile separator "\t"

set style line 11 lc rgb '#808080' lt 1
set border 11 back ls 11
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12
set style line 4 lc rgb '#8b1a0e' lt 1 lw 3 pt 7 ps 1 #red
set style line 2 lc rgb '#0c119c' lt 1 lw 3 pt 7 ps 1 #blue
set style line 3 lc rgb '#5e9c36' lt 1 lw 3 pt 13 ps 1 #green
set style line 1 lc rgb '#ff9900' lt 1 lw 3 pt 13 ps 1 #green
set style fill transparent solid 0.5 border

set lmargin 9
set rmargin 2

set key top right autotitle columnhead invert opaque samplen 2 width 2

set xlabel "Time (min)"

set ylabel "Throughput (ktps)"

file = dir."/buffersizes.txt"

plot for [i=1:ncolumns] file using (column(0)/60):i with lines ls i
