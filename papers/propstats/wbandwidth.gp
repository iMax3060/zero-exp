set terminal cairolatex standalone pdf size 12cm,5cm dashed transparent font "default,8" \
    header "\\usepackage{xcolor}"
set output "wbandwidth.tex"

set style line 11 lc rgb '#000000' lt 1
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12
set style line 1 lc rgb '#8b1a0e' lt 1 lw 4 pt 7 ps 1 #red
set style line 2 lc rgb '#0c119c' lt 1 lw 4 pt 6 ps 1 #blue
set style line 3 lc rgb '#5e9c36' lt 1 lw 4 pt 13 ps 1 #green

set lmargin 9
set rmargin 7
# set tmargin 1.5

set border 11 back ls 11

set boxwidth 0.7
set style fill solid

set xtics nomirror rotate by -45
set xlabel "Propagation strategy" offset 0,-1

set ytics nomirror 2,2
set ylabel "Write bandwidth (MB/s)"
set logscale y
set yrange[2:128]

# columns are:
# dirty_pages redo_length page_writes xct_end updates
plot dir."/avg_write_bwidth.txt" using (column(0)):($2/128):xtic(1) with boxes ls 2 notitle
