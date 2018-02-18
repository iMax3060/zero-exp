set terminal cairolatex standalone pdf size 8.5cm,6cm dashed transparent font "default,9"
set output "iostat_".mytitle.".tex"

set title "Segment size = " . mytitle

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
unset mytics

set xlabel "Time (min)"
set xtics mirror

file = dir."/iostat_dev.txt" 
plot file using (column(0)/60):1 with lines ls 1 t "Log arch. read", \
    "" using (column(0)/60):2 with lines ls 2 t "Backup read", \
    "" using (column(0)/60):3 with lines ls 3 t "Repl. write", \
    "" using (column(0)/60):4 with lines ls 4 t "DB read"
