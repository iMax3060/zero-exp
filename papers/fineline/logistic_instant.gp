set terminal cairolatex standalone pdf size 8.5cm,3.3cm color colortext dashed transparent font "default,8"
set output "logistic_instant.tex"

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
set style line 1 lw 3 lc rgb '#1B9E77' # dark teal
set style line 2 lw 3 lc rgb '#D95F02' # dark orange
set style line 3 lw 3 lc rgb '#7570B3' # dark lilac
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
set tmargin 2

set style fill solid 0.2

set key bottom inside right autotitle columnhead invert opaque samplen 2 width 2

set xlabel "Time"
set format x ""
set xrange[-10:20]

set ylabel "Txn. throughput"
set format y ""

f(x)=1/(1+(1/exp(4*(x-9)))) 
g(x)=1/(1+(1/exp(x-1))) 

set obj 10 rect at -6,graph 0.6 size 5,0.15 fc 'white' front
set label "region 1" at -8, graph 0.6 front

set obj 11 rect at 4,graph 0.3 size 5,0.15 fc 'white' front
set label "region 2" at 2, graph 0.3 front

set style line 9 lw 2 dt 4 lc rgb '#D95F02' # dark orange
set arrow from -9,graph 0 to -9,graph 1.05 ls 9  nohead front
set label "offline end" at -9, graph 1.1 center front textcolor rgb '#d95f02'

set style line 10 lw 2 dt 4 lc rgb '#1B9E77' # dark teal
set arrow from 7,graph 0 to 7,graph 1.05 ls 10  nohead front
set label "offline end" at 7, graph 1.1 center front textcolor rgb '#1b9e77'

plot '+' using 1:(f($1)):(g($1)) with filledcurves closed notitle lc rgb '#8fe0c8' fs pattern 7, \
     '+' using 1:(1):(g($1)) with filledcurves above notitle lc rgb '#f2b98e' fs pattern 6 , \
    f(x) with lines ls 1 title "ARIES restart", \
    g(x) with lines ls 2 title "Instant restart"
