set terminal cairolatex standalone pdf size 8.5cm,5cm dashed transparent font "default,9"
set output "accum_".bufsize.".tex"

set style line 11 lc rgb '#000000' lt 1
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12
set style line 1 lc rgb '#8b1a0e' lt 1 lw 3 pt 7 ps 1 #red
set style line 2 lc rgb '#0c119c' lt 1 lw 3 pt 6 ps 1 #blue
set style line 3 lc rgb '#5e9c36' lt 1 lw 1 pt 13 ps 1 #green
set style line 4 lc rgb '#5e9c36' lt 2 lw 8 pt 13 ps 1
set style line 5 lc rgb '#1faede' lt 1 lw 1 pt 6 ps 1 #blue
set style fill transparent solid 0.2 border

set lmargin 9
set rmargin 1

#set title "Buffer size = " . bufsize . " GB"
set border 11 back ls 11
unset key 

set xtics nomirror
set xlabel "Time (sec)"
#set ytics 1,1 nomirror
set ylabel "{\\small Transactions committed (millions)}"
unset mytics

file = dir."/agglog_accum.txt" 
plot file using (column(0)):($1/1000000) with lines axes x1y1 ls 2
