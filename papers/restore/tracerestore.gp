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

set terminal cairolatex standalone pdf size 8.5cm,5cm dashed color colortext transparent font "default,9"
set output "tracerestore_".mytitle.".tex"
set title "Segment size = " . mytitle . " KB"

# set key as column head and then unset it, just to ignore first line
set key autotitle columnhead
unset key

set tics textcolor rgb "#000000"

set xtics nomirror
set xlabel "Time (min)"
set xrange[0:20]

set ylabel "Segment number ($\\times 10^3$)"
set ytics nomirror
set yrange [0:]

plot dir."/tracerestore.txt" using ($1/60):($2/1000) with points ls 3 pt 0 ps 0.5 notitle
