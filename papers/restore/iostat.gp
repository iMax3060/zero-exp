# line styles for ColorBrewer Dark2
# for use with qualitative/categorical data
# provides 8 dark colors based on Set2
# compatible with gnuplot >=4.2
# author: Anna Schneider

# line styles
set style line 1 lw 1 lc rgb '#1B9E77' # dark teal
set style line 2 lw 1 lc rgb '#D95F02' # dark orange
set style line 3 lw 1 lc rgb '#7570B3' # dark lilac
set style line 4 lw 1 lc rgb '#E7298A' # dark magenta
set style line 5 lw 1 lc rgb '#66A61E' # dark lime green
set style line 6 lw 1 lc rgb '#E6AB02' # dark banana
set style line 7 lw 1 lc rgb '#A6761D' # dark tan
set style line 8 lw 1 lc rgb '#666666' # dark gray

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

set terminal cairolatex standalone pdf size 8.5cm,6cm dashed transparent font "default,9"
set output "iostat_".mytitle.".tex"

set title "Segment size = " . mytitle . " GB"

set style line 11 lc rgb '#808080' lt 1
set border 3 back ls 11
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12
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
# set xrange [0:900]

file = dir."/iostat_dev.txt" 
plot file using (column(0)/12):1 with lines ls 1 t "Log W", \
    "" using (column(0)/12):2 with lines ls 2 t "Log R", \
    "" using (column(0)/12):3 with lines ls 3 t "Arch W", \
    "" using (column(0)/12):4 with lines ls 4 t "Arch R", \
    "" using (column(0)/12):5 with lines ls 5 t "DB W", \
    "" using (column(0)/12):6 with lines ls 6 t "DB R", \
    "" using (column(0)/12):7 with lines ls 7 t "Bkp W", \
    "" using (column(0)/12):8 with lines ls 8 t "Bkp R"
