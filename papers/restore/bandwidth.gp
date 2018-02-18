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

set terminal cairolatex standalone pdf size 8.5cm,4cm dashed color colortext transparent font "default,9"
set output "bandwidth.tex"

# set key as column head and then unset it, just to ignore first line
set key autotitle columnhead
unset key

set xtics nomirror
set xlabel "Segment size"

set ylabel "Bandwidth (MB/s)"
set ytics nomirror 0,20
set yrange [0:]

set boxwidth 0.7
plot dir."/bandwidth.txt" using ($2):xtic(1) with boxes ls 3 t "Bandwidth"
