set terminal cairolatex standalone pdf size 8.5cm,6cm dashed transparent font "default,9"
set output "iostat_".bufsize.".tex"

set title "Buffer size = " . bufsize . " GB"

set style line 11 lc rgb '#808080' lt 1
set border 3 back ls 11
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12
set style line 1 lc rgb '#8b1a0e' lt 1 lw 1 pt 7 ps 1 #red
set style line 2 lc rgb '#0c119c' lt 1 lw 1 pt 6 ps 1 #blue
set style line 3 lc rgb '#5e9c36' lt 1 lw 1 pt 13 ps 1 #green
set style line 4 lc rgb '#aa6699' lt 1 lw 1 pt 13 ps 1
set style fill transparent solid 0.2 border

set lmargin 9
#set rmargin 2

set key outside bottom center vertical maxrows 2 samplen 2

set ytics nomirror
set ylabel "Bandwidth (MB/s)"
set yrange [0:280]
unset mytics

set xlabel "Time (min)"
set xtics mirror
set mxtics 10
set xrange [0:900]

file = dir."/iostat_dev.txt" 
plot file using (column(0)/1):1 with lines ls 1 t "Arch W", \
    "" using (column(0)/1):2 with lines ls 2 t "Arch R", \
    "" using (column(0)/1):3 with lines ls 3 t "Log W", \
    "" using (column(0)/1):4 with lines ls 4 t "Log R"
