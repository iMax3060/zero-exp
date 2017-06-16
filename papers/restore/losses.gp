set terminal cairolatex standalone pdf size 8.5cm,4cm dashed transparent font "default,9"
set output "losses.tex"

set style line 11 lc rgb '#808080' lt 1
set border 11 back ls 11
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12
set style line 1 lc rgb '#8b1a0e' lt 1 lw 1 pt 7 ps 1 #red
set style line 2 lc rgb '#0c119c' lt 1 lw 2 pt 7 ps 1 #blue
set style line 3 lc rgb '#5e9c36' lt 1 lw 2 pt 13 ps 1 #green
set style fill transparent solid 0.5 border

set lmargin 8
set rmargin 1

#set key center bottom outside maxrows 1 width 2
unset key

set xtics nomirror
set xlabel "Buffer size (GB)"

set ylabel "Transaction miss {\\small($\\times 10^6$)}"
set ytics nomirror 0,5
set yrange [0:]

set boxwidth 0.7
plot dir."/losses.txt" using ($2/1000000):xtic(1) with boxes ls 2 t "Loss"
 #    "bandwidth.txt" using ($2) with linespoints axes x1y2 ls 3 t "Bandwidth"
