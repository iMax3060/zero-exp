#set terminal cairolatex standalone pdf size 8.5cm,6cm dashed transparent

set style line 11 lc rgb '#000000' lt 1
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid front ls 12
set style line 1 lc rgb '#8b1a0e' lt 1 lw 3 pt 7 ps 1 #red
set style line 2 lc rgb '#0c119c' lt 1 lw 1 pt 6 ps 1 #blue
set style line 3 lc rgb '#5e9c36' lt 1 lw 1 pt 13 ps 1 #green
set style line 4 lc rgb '#5e9c36' lt 2 lw 8 pt 13 ps 1
set style line 5 lc rgb '#1faede' lt 1 lw 1 pt 6 ps 1 #blue
set style fill transparent solid 0.2 border

set lmargin 8
set rmargin 8

set terminal cairolatex standalone pdf size 19cm,6cm dashed transparent font "default,9"
set key center bottom outside vertical maxrows 1
set key samplen 4 width 1

unset border
unset tics
set output "key.tex"
plot [0:1] [0:1] NaN with lines ls 1 lw 5 title "Throughput", \
    NaN with lines ls 5 lw 5 title "Page reads", \
    NaN with lines ls 4 title "Pre-failure throughput"

set terminal cairolatex standalone pdf size 8.5cm,5cm dashed transparent font "default,9"
set output "tput_".bufsize.".tex"

set title "Buffer size = " . bufsize . " GB"
set border 11 back ls 11
unset key 

set xtics nomirror 0,5
set xlabel "Time (min)"

set yrange [0:ymax]
set ytics nomirror
set ylabel "Transaction throughput (ktps)"
unset mytics

set logscale y2
set y2tics nomirror
set y2label "Page reads/sec"
set format y2 "$10^{%L}$"
unset my2tics

set style rect fc lt -1 fs solid 0.15 noborder
set obj rect from rbegin/60, graph 0 to rend/60, graph 1

file = dir."/agglog_smooth.txt" 
#stats file using (column(0)):($1/1000) nooutput
#set label "$\left{\rule{0cm}{1cm}\right.$" at rbegin/60,(STATS_max_y + 0.25)

plot file using (column(0)/60):($7) with lines axes x1y2 ls 5 , \
    ""  using (column(0)/60):($1/1000) with lines axes x1y1 ls 1 , \
    "" using (column(0)/60):($5 > 0 ? $5/1000 : 1/0) with lines axes x1y1 ls 4 
