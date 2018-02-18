set terminal cairolatex standalone pdf size 8cm,6cm dashed color colortext transparent font "default,8"
set output "backlog.tex"

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
set style line 1 lw 2 lc rgb '#1B9E77' # dark teal
set style line 2 lw 2 lc rgb '#D95F02' # dark orange
set style line 3 lw 2 lc rgb '#7570B3' # dark lilac
set style line 4 lw 2 lc rgb '#E7298A' # dark magenta
set style line 5 lw 2 lc rgb '#66A61E' # dark lime green
set style line 6 lw 2 lc rgb '#E6AB02' # dark banana
set style line 7 lw 2 lc rgb '#A6761D' # dark tan
set style line 8 lw 2 lc rgb '#666666' # dark gray

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
set key outside bottom right horizontal opaque Right  width 3
# set key width -5

# set lmargin 9
# set rmargin 9
# set tmargin 1.5

set xtics nomirror
set xlabel "Time (minutes)"
# set xrange [0:(rend/60)+10]

set ytics nomirror
set ylabel "Dirty pages ($\\times 10^3$)"
unset mytics

set y2tics nomirror
set y2label "REDO length (GB)"

# columns are:
# dirty_pages redo_length page_writes xct_end updates
plot dir."/propstats_ext.txt" using (column(0)/60):(column(1)/1000) with lines ls 1 t "\\small Dirty pages (total)", \
       "" using (column(0)/60):(column(6)/1000) with lines ls 3 axes x1y1 t "\\small Dirty pages (static)", \
       "" using (column(0)/60):(column(2)/1000) with lines ls 4 axes x1y2 t "\\small REDO length"
