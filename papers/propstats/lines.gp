set style line 11 lc rgb '#000000' lt 1
set style line 12 lc rgb '#666666' lt 0 lw 1
set grid back ls 12

set style line 1 lw 5 lc rgb '#762A83' # dark purple
set style line 2 lw 5 lc rgb '#0066ff' # blue
set style line 3 lw 5 lc rgb '#b30000' # dark red
set style line 4 lw 5 lc rgb '#1B7837' # dark green

#######
# PLOT KEY
######

set terminal cairolatex standalone pdf size 14cm,6cm dashed transparent font "default,9" \
    header "\\usepackage{xcolor} \\usepackage{xstring}"
set key center bottom outside vertical maxrows 1
set key samplen 4 width 1

unset border
unset tics
set output "key.tex"
i=0
set yrange [-1:1]
plot for [exp in list] 1/0 \
    with lines t "\\StrSubstitute{".exp."}{_}{-}" ls i=i+1

#######
# PLOT GRAPHS
######

set terminal cairolatex standalone pdf size 14cm,3.3cm dashed transparent font "default,8" \
    header "\\usepackage{xcolor} \\usepackage{xstring}"
set output "lines.tex"

set multiplot layout 1,2

unset key
#set key top left width 0.5 samplen 2 spacing 1.2 reverse invert

set lmargin 10
set rmargin 2
# set tmargin 1.5

set border 11 back ls 11

set yrange [0:*]

# columns are:
# dirty_pages redo_length page_writes xct_end updates

# FIRST PLOT (dirty pages)
set xtics nomirror 0,2
set xlabel "Time (minutes)"
set ytics nomirror
set ylabel "Dirty pages ($\\times 10^3$)"
unset mytics

i=0
plot for [exp in list] sprintf("%s/%s/propstats_ext.txt", dir, exp) \
    using (column(0)/60):($1/1000) with lines t "\\StrSubstitute{".exp."}{_}{-}" ls i=i+1

# SECOND PLOT (redo length)
set ylabel "REDO length (GB)"

i=0
plot for [exp in list] sprintf("%s/%s/propstats_ext.txt", dir, exp) \
    using (column(0)/60):($2/1024) with lines t "\\StrSubstitute{".exp."}{_}{-}" ls i=i+1
