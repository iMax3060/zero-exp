set terminal cairolatex standalone pdf size 8.5cm,5cm dashed transparent font "default,9"
set output "bandwidth_".prefix.".tex"

set style line 11 lc rgb '#000000' lt 1
set border 11 back ls 11
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12 

set style line 1 lc rgb '#8b1a0e' lt 1 lw 2 pt 7 ps 1 #red
set style line 2 lc rgb '#0c119c' lt 1 lw 2 pt 5 ps 1 #blue
set style line 3 lc rgb '#5e9c36' lt 1 lw 2 pt 13 ps 1 #green
set style line 4 lc rgb '#5e9c9c' lt 1 lw 2 pt 14 ps 1 #purple
set style fill transparent solid 0.6 border

set lmargin 8
set rmargin 6

set key top left samplen 2 
set key inside invert reverse 

set xtics nomirror
set xtics rotate by -45
set xlabel "Segment size" offset -2

set ylabel "Bandwidth (MB/s)"
unset mytics

set boxwidth 0.8

plot prefix."-arch1/bandwidth.txt" using 2:xtic(1) with linespoints ls 3 t "64 runs", \
    prefix."-arch2/bandwidth.txt" using 2 with linespoints ls 1 t "24 runs", \
    prefix."-arch3/bandwidth.txt" using 2 with linespoints ls 2 t "8 runs"

