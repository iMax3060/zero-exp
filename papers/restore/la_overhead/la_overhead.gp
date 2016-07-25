set terminal cairolatex standalone pdf size 8.5cm,4cm dashed transparent font "default,9"
set output "la_overhead.tex"
set datafile separator "\t"

set style line 11 lc rgb '#808080' lt 1
set border 11 back ls 11
set style line 12 lc rgb '#999999' lt 0 lw 1
set grid back ls 12
set style line 1 lc rgb '#8b1a0e' lt 1 lw 5 pt 7 ps 1 #red
set style line 2 lc rgb '#0c119c' lt 1 lw 2 pt 7 ps 1 #blue
set style line 3 lc rgb '#5e9c36' lt 1 lw 2 pt 13 ps 1 #green
set style line 4 lc rgb '#303030' lt 1 lw 3 pt 13 ps 1 #darkgrey
set style fill transparent solid 0.5 border

set lmargin 9
set rmargin 1

set multiplot layout 1,2

set auto x
unset xtics
set xtics nomirror scale 0 font ",8"
set xrange [-0.5:1.5]
#set xlabel "Configuration"

set style fill empty
set boxwidth 0.5
set style data candlesticks 
unset mytics
set ylabel "Throughput (ktps)"
#set logscale y
#set ytics 1,2
#set yrange [2:16]

#set title "SSD"

# x min 1st mean 2nd max
plot dir."/la_overhead_1.txt" using (column(0)):3:2:6:5:xtic(1) ls 4 notitle whiskerbars, \
    "" using (column(0)):4:4:4:4:xtic(1) with candlesticks ls 1 notitle

unset ylabel
unset xlabel
set lmargin 7
#set yrange [8:70]
#set title "DRAM"
set ylabel "CPU utilization (\\%)"

plot dir."/cpu_util_1.txt" using (column(0)):3:2:6:5:xtic(1) ls 4 notitle whiskerbars, \
    "" using (column(0)):4:4:4:4:xtic(1) with candlesticks ls 1 notitle
