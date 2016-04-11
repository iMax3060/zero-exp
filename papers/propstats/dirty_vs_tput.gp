set terminal cairolatex standalone pdf size 8.5cm,5cm dashed transparent font "default,8" \
    header "\\usepackage{xcolor}"
set output "dirty_vs_tput.tex"

set multiplot layout 2,1

set style line 11 lc rgb '#000000' lt 1
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12
set style line 1 lc rgb '#8b1a0e' lt 1 lw 4 pt 7 ps 1 #red
set style line 2 lc rgb '#0c119c' lt 1 lw 4 pt 6 ps 1 #blue
set style line 3 lc rgb '#5e9c36' lt 1 lw 4 pt 13 ps 1 #green
set style fill transparent solid 0.2 border

set key bottom right opaque
set key width -5

set lmargin 9
set rmargin 2
# set bmargin at screen 0.6
# set tmargin at screen 0.98

set border 11 back ls 11

# FIRST PLOT (hifreq)
set ytics nomirror 50,50
set ylabel "Page count"
# set yrange [0:240]
set format y "%.0fk"
set xtics format ""
set xrange [0:8]

unset xlabel

plot dir."/propstats.txt" using (column(0)/60):($1/1000) with lines ls 1 t "\\small Dirty pages"

# SECOND PLOT (lowfreq)
set tmargin 0
set key top right opaque

set ylabel "Throughput (tps)"
set ytics nomirror 1000,2000
set format y "%.0f"
set xlabel "Time (min)"
set xtics format "%.0f"

plot dir."/propstats.txt" using (column(0)/60):($4) with lines ls 2 axes x1y2 t "\\small Transaction tput"
