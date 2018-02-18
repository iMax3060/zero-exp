set style line 11 lc rgb '#808080' lt 1
set border 11 back ls 11
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12

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

# set lmargin 8
# set rmargin 8

# set terminal cairolatex standalone pdf size 19cm,6cm dashed transparent font "default,9"
# set key center bottom outside vertical maxrows 1
# set key samplen 4 width 1

# unset border
# unset tics
# set output "key.tex"
# plot [0:1] [0:1] NaN with lines ls 1 lw 5 title "Throughput", \
#     NaN with lines ls 5 lw 5 title "Page reads", \
#     NaN with lines ls 4 title "Pre-failure throughput"

set terminal cairolatex standalone pdf size 8.5cm,5cm dashed color colortext transparent font "default,9"
set output "tput_".mytitle.".tex"

set title "Buffer size = " . mytitle2 . " GB"
unset key 

set xtics nomirror 0,5
set xlabel "Time (min)"
set xrange [0:20]

set yrange [0:25]
set ytics nomirror
set ylabel "Transaction throughput (ktps)"
unset mytics

# set logscale y2
# set y2tics nomirror
# set y2label "Page reads/sec"
# set format y2 "$10^{%L}$"
# unset my2tics

set style rect fc lt -1 fs solid 0.25 noborder
set obj rect fc rgb "#a6761d" from rbegin/60, graph 0 to rend/60, graph 1

file = dir."/agglog_smooth.txt" 
#stats file using (column(0)):($1/1000) nooutput
#set label "$\left{\rule{0cm}{1cm}\right.$" at rbegin/60,(STATS_max_y + 0.25)

plot file using (column(0)/60):($1/1000) with lines axes x1y1 ls 2

# plot file using (column(0)/60):($1/1000) with lines axes x1y1 ls 1 , \
#     "" using (column(0)/60):($5 > 0 ? $5/1000 : 1/0) with lines axes x1y1 ls 4 

# plot file using (column(0)/60):($7) with lines axes x1y2 ls 5 , \
#     ""  using (column(0)/60):($1/1000) with lines axes x1y1 ls 1 , \
#     "" using (column(0)/60):($5 > 0 ? $5/1000 : 1/0) with lines axes x1y1 ls 4 
