set terminal cairolatex standalone pdf size 8cm,4cm color colortext dashed transparent font "default,8"
set output "txndiff.tex"

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
set style line 1 lw 1 lc rgb '#1B9E77' # dark teal
set style line 2 lw 1 lc rgb '#D95F02' # dark orange
set style line 3 lw 1 lc rgb '#7570B3' # dark lilac
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

set lmargin 7
set rmargin 2
set tmargin 3

set style data histogram
set style fill solid 1 border -1
set style histogram cluster gap 1

set key top inside left opaque samplen 2 width 2
set tics textcolor rgb "black"

set xlabel "Redo length (GB)"
set xrange [-1:ncols]

set title "Difference in missed transactions"

set ylabel "Transactions ($\\times 10^6$)"
set ytics 0,4
set yrange [0:]

plot dir."/txnmiss.txt" using ($4/1000000):xtic(1) ls 3 notitle
