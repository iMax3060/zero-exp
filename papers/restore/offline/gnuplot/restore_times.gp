set terminal pngcairo dashed size 600,400
set output dir."/restore_times.png"

set style line 11 lc rgb '#808080' lt 1
set border 11 back ls 11
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12
set style line 1 lc rgb '#8b1a0e' lt 1 lw 1 pt 7 ps 1 #red
set style line 2 lc rgb '#0c119c' lt 1 lw 1 pt 6 ps 1 #blue
set style line 3 lc rgb '#5e9c36' lt 1 lw 1 pt 13 ps 1 #green
set style line 4 lc rgb '#5e9c9c' lt 1 lw 1 pt 14 ps 1 #purple
set style fill transparent solid 0.2 border

# Histogram options
set style data histogram
set style histogram cluster gap 1

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
set ylabel "Time (usec)"
# set format y "%.0s"
unset mytics

set boxwidth 0.7

plot dir."/restore_time_read.txt" using 2:xtic(1) ls 1 t "Read", \
    dir."/restore_time_openscan.txt" using 2 ls 2 t "Open scan", \
    dir."/restore_time_replay.txt" using 2 ls 3 t "Replay", \
    dir."/restore_time_write.txt" using 2 ls 4 t "Write"

