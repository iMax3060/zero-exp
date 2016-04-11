set terminal cairolatex standalone pdf size 8.5cm,3.3cm dashed transparent font "default,8" \
    header "\\usepackage{xcolor}"
set output "backlog.tex"

set style line 11 lc rgb '#000000' lt 1
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12
set style line 1 lc rgb '#8b1a0e' lt 1 lw 4 pt 7 ps 1 #red
set style line 2 lc rgb '#0c119c' lt 1 lw 4 pt 6 ps 1 #blue
set style line 3 lc rgb '#5e9c36' lt 1 lw 4 pt 13 ps 1 #green
set style fill transparent solid 0.2 border

set title "\\detokenize{".dir."}"
set key top left opaque
set key width -5

set lmargin 9
set rmargin 9
# set tmargin 1.5

set border 11 back ls 11

set xtics nomirror
set xlabel "Time (minutes)"
# set xrange [0:(rend/60)+10]

set ytics nomirror
set ylabel "Dirty pages ($\\times 10^3$)"
# set yrange[0:16.0]
unset mytics

set y2tics nomirror
set y2label "REDO length (MB)"
# set y2range[0:16.0]
# unset my2tics

# columns are:
# dirty_pages redo_length page_writes xct_end updates
plot dir."/propstats_ext.txt" using (column(0)/60):($1/1000) with lines ls 1 t "\\small Dirty pages", \
       "" using (column(0)/60):4 with lines ls 2 axes x1y2 t "\\small REDO length"
