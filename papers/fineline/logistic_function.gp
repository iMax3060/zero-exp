set terminal cairolatex standalone pdf size 8.5cm,3.3cm dashed transparent font "default,8" \
    header "\\usepackage{xcolor}"
set output "logistic_function.tex"

set style line 11 lc rgb '#808080' lt 1
set border 11 back ls 11
set style line 12 lc rgb '#444444' lt 0 lw 1
set style fill transparent solid 0.5 border

# line styles for ColorBrewer Dark2
# for use with qualitative/categorical data
# provides 8 dark colors based on Set2
# compatible with gnuplot >=4.2
# author: Anna Schneider

# line styles
set style line 1 lw 3 lc rgb '#1B9E77' # dark teal
set style line 2 lw 3 lc rgb '#D95F02' # dark orange
set style line 3 lw 5 lc rgb '#7570B3' # dark lilac
set style line 4 lw 3 lc rgb '#E7298A' # dark magenta
set style line 5 lw 3 lc rgb '#66A61E' # dark lime green
set style line 6 lw 3 lc rgb '#E6AB02' # dark banana
set style line 7 lw 3 lc rgb '#A6761D' # dark tan
set style line 8 lw 3 lc rgb '#666666' # dark gray

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

set lmargin 6
set rmargin 2

set style fill solid 0.2

set key bottom inside right autotitle columnhead invert opaque samplen 2 width 2

set xlabel "Time"
set format x ""
set xrange[-10:20]

set ylabel "Txn. throughput"
set format y ""

f(x)=1/(1+(1/exp(x-1))) 

set arrow from -10, graph 0.7 to -5, graph 0.7 lc rgb '#000000' lw 1 lt 4
set arrow from -5, graph 0.7 to 6, graph 0.7 lc rgb '#000000' lw 1 lt 4
set arrow from 6, graph 0.7 to 20, graph 0.7 lc rgb '#000000' lw 1 lt 4

set style rect fc lt -1 fs solid 0.25 noborder
set obj rect from -10, graph 0 to -5, graph 1
set style rect fc lt -1 fs solid 0.15 noborder
set obj rect from -5, graph 0 to 6, graph 1
set style rect fc lt -1 fs solid 0.05 noborder
set obj rect from 6, graph 0 to 20, graph 1

set label "1) offline" at -9.75, graph 0.75 front
set label "2) warm-up" at -4.5, graph 0.75 front
set label "3) steady state" at 6.5, graph 0.75 front

plot f(x) with lines lc rgb '#201a82' lw 5 notitle
