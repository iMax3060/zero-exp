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

# Plot key in separate file
set terminal cairolatex standalone pdf size 17cm,1cm dashed transparent font "default,9"
set key center bottom outside vertical maxrows 1
set key samplen 4 width 1

unset border
unset tics
set output "key.tex"
plot [0:1] [0:1] NaN with lines ls 1 lw 5 title "ARIES restart", \
    NaN with lines ls 2 lw 5 title "Instant restart"

set terminal cairolatex standalone pdf size 8cm,4cm dashed color colortext transparent font "default,8"
set output "instantrestart.tex"
set datafile separator "\t"

set style line 11 lc rgb '#808080' lt 1
set border 11 back ls 11
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12

set tics textcolor rgb "black"

set title "Redo length = " . redolen . " GB"

set lmargin 9
set rmargin 2
set tmargin 3

set style fill solid 0.2

#set key bottom inside right autotitle columnhead invert opaque samplen 2 width 2
unset key

set xlabel "Time (min)"
set xrange [0:360]
set xtics 0,60
set mxtics 4

set ylabel "Throughput (ktps)"
# set yrange [0:90]
set ytics

#set decimal locale
#set label "Area diff. = ".sprintf("%'.0f",txndiff) at 5,32

file = dir."/tput.txt"

plot file using (column(0)/60):(column(1)/1000):(column(2)/1000) with filledcurves above notitle lc rgb '#1B9E77', \
    '' using (column(0)/60):(column(1)/1000):(column(2)/1000) with filledcurves below notitle lc rgb '#d95f02', \
    '' using (column(0)/60):(column(1)/1000) with lines ls 1 title "ARIES restart", \
    '' using (column(0)/60):(column(2)/1000) with lines ls 2 title "Instant restart"
