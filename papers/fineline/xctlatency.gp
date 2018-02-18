# line styles for ColorBrewer Dark2
# for use with qualitative/categorical data
# provides 8 dark colors based on Set2
# compatible with gnuplot >=4.2
# author: Anna Schneider

# line styles
set style line 1 lw 6 lc rgb '#1B9E77' # dark teal
set style line 2 lw 6 lc rgb '#D95F02' # dark orange
set style line 3 lw 6 lc rgb '#7570B3' # dark lilac
set style line 4 lw 6 lc rgb '#E7298A' # dark magenta
set style line 5 lw 6 lc rgb '#66A61E' # dark lime green
set style line 6 lw 6 lc rgb '#E6AB02' # dark banana
set style line 7 lw 6 lc rgb '#A6761D' # dark tan
set style line 8 lw 6 lc rgb '#666666' # dark gray

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

set terminal cairolatex standalone pdf size 8.5cm,4cm dashed transparent font "default,9"
set output "xctlatency.tex"
set datafile separator "\t"

set style line 11 lc rgb '#808080' lt 1
set border 11 back ls 11
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12
set tics textcolor rgb "black"

set lmargin 9
set rmargin 2

# set key top right autotitle columnhead invert opaque samplen 2 width 2
unset key

set xlabel "Time (min)"
set xrange [0:14]

set ylabel "Latency (ms)"
set ytics 0.1,10 nomirror
set yrange [0.1:1000]
set logscale y

set title "Redo length = ".redolen." GB"

file = dir."/xctlatency.txt"

plot for [i=1:ncolumns] file using (column(0)/60):i with lines ls i
