set terminal cairolatex standalone pdf size 8.5cm,3.3cm dashed transparent font "default,8" \
    header "\\usepackage{xcolor}"
set output "tput_simple.tex"

set style line 11 lc rgb '#000000' lt 1
set style line 12 lc rgb '#444444' lt 0 lw 1
set grid back ls 12
set style line 1 lc rgb '#8b1a0e' lt 1 lw 4 pt 7 ps 1 #red
set style line 2 lc rgb '#0c119c' lt 1 lw 4 pt 6 ps 1 #blue
set style line 3 lc rgb '#5e9c36' lt 1 lw 4 pt 13 ps 1 #green
set style fill transparent solid 0.2 border

set key at 36.5,7 opaque
set key width -5

set lmargin 8
set rmargin 2
set tmargin 1.5

set border 11 back ls 11

set xtics nomirror
set xlabel "Time (minutes)"
set xrange [0:(rend/60)+10]

set label "\\footnotesize \\textit{pre-failure}" at 2,10
set label "\\footnotesize \\textit{post-restore}" at 29,10

set ytics nomirror 0,4
set ylabel "Throughput (ktps)"
set yrange[0:16.0]
unset mytics

set label "\\color[HTML]{CC0000}\\Huge\\textbf{$\\downarrow$}" at rbegin/60-0.6,15
set label "\\color[HTML]{CC0000}\\textbf{Media failure}" at rbegin/60-5,17

file = "/agglog_super_smooth.txt" 

plot dir1.file using (column(0)/60):($1/1000) with lines ls 1 t "\\small Single-pass restore" , \
     dir2.file using (column(0)/60):($1/1000) with lines ls 3 t "\\small Instant restore \\footnotesize (small buffer)" , \
     dir3.file using (column(0)/60):($1/1000) with lines ls 2 t "\\small Instant restore \\footnotesize (large buffer)" , \
