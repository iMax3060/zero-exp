set terminal pngcairo dashed size 800,400
set output outfile

set title "Segment size = " . segsize

set style line 11 lc rgb '#808080' lt 1
set border 3 back ls 11
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12
set style line 1 lc rgb '#8b1a0e' lt 1 lw 1 pt 7 ps 1 #red
set style line 2 lc rgb '#0c119c' lt 1 lw 1 pt 6 ps 1 #blue
set style line 3 lc rgb '#5e9c36' lt 1 lw 1 pt 13 ps 1 #green
set style fill transparent solid 0.2 border

set lmargin 8
#set rmargin 2

set key top right
set key outside

# FIRST PLOT (Throughput)
# set xtics mirror 20,20
set xlabel "Time (sec)"
set ytics 10,20 nomirror
# set yrange [0:90]
set ylabel "Bandwidth (MB/s)"
# set format y "%.0s"
unset mytics

plot file using (column(0)):1 with lines ls 1 t "Log arch. read", \
    "" using (column(0)):2 with lines ls 2 t "Backup read", \
    "" using (column(0)):3 with lines ls 3 t "Repl. write"
