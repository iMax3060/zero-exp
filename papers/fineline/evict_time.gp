set terminal cairolatex standalone pdf size 7cm,4cm color colortext transparent font "default,8"
set output "evict_time_" . bufsize . ".tex"
set datafile separator "\t"

set style line 11 lc rgb '#808080' lt 1
set border 11 back ls 11
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12
set style fill transparent solid 0.5 border

# line styles for ColorBrewer Dark2
# for use with qualitative/categorical data
# provides 8 dark colors based on Set2
# compatible with gnuplot >=4.2
# author: Anna Schneider

# line styles
set style line 1 lw 4 lc rgb '#1B9E77' # dark teal
set style line 2 lw 4 lc rgb '#D95F02' # dark orange
set style line 3 lw 4 lc rgb '#7570B3' # dark lilac
set style line 4 lw 4 lc rgb '#E7298A' # dark magenta
set style line 5 lw 4 lc rgb '#66A61E' # dark lime green
set style line 6 lw 4 lc rgb '#E6AB02' # dark banana
set style line 7 lw 4 lc rgb '#A6761D' # dark tan
set style line 8 lw 4 lc rgb '#666666' # dark gray

# palette
set palette maxcolors 8
set palette defined ( 0 '#1B9E77',\
    	    	      1 '#D95F02',\
		      2 '#7570B3',\
		      3 '#E7298A',\
		      4 '#66A61E',\
		      5 '#E6AB02',\
		      6 '#A6761D',\
		      7 '#666666' )
set tics textcolor rgb "black"

# set lmargin 7
# set rmargin 11

set key outside right top invert horizontal Right opaque width 4

set xlabel "Time (min)"
set xrange [0:25]
# set xtics 0,30
# set mxtics 4

set y2label "Avg. evict time (ms)" offset 1.5 rotate by 270
set logscale y2
set y2tics
set format y2 "$10^{%L}$"
unset my2tics
set y2range [0.00001:10]

set ylabel "Throughput (ktps)" offset -1
set yrange [0:30]

file1 = dir."/evict_time_smooth.txt"
file2 = dir."/agglog_smooth.txt"

plot file1 using (column(0)/60):($1/1000000/threads) with lines axes x1y2 ls 2 title "Evict time", \
    file2 using (column(0)/60):($1/1000) with lines axes x1y1 ls 3 title "Txn. throughput"
