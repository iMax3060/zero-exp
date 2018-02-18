set terminal cairolatex standalone pdf size 7cm,3cm color colortext transparent font "default,8"
set output "writesizes_".bufsize.".tex"

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

# set title "\\detokenize{".dir."}"
# set key outside bottom
set key outside top right horizontal opaque Right  width 3
# set key width -5

# set lmargin 8
# set rmargin 8
# set tmargin 1.5

set xtics nomirror
set xlabel "Write size ($\\times 10^3$ pages of 8\\,KB)"
set logscale y
# set xrange [1:1850]
# set xtics 0,200

set ytics nomirror
set ylabel "Frequency"
unset mytics
set format y "$10^{%L}$"
set yrange [1:1000000]
# set format y "%.1f"

set decimal locale
set label "Single-page writes = ".sprintf("%'.0f",spwrites) at graph 0.2,graph 0.7

# binwidth=100
# bin(x,width)=(x <= 8 ? x : width*floor(x/width))
# set boxwidth binwidth

# plot dir."/writesizes.txt" using (bin(column(0),binwidth)):2 smooth freq with boxes notitle
plot dir."/writesizes.txt" using (column(0)/1000):2 with lines ls 2 notitle
