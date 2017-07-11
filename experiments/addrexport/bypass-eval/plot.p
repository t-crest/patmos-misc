set terminal postscript eps enhanced color font 'Helvetica,10'
set boxwidth 1 relative
set style data histograms
set style fill solid  1.00 border -1
set nokey
set datafile missing '-'
set xtics border in scale 0,0 nomirror rotate by -45  offset character 0, 0, 0 autojustify
set xtics  norangelimit font ",8"
set xtics   ()
set grid ytics lt 0
set title "Reduction of WCET bound in \% with the bypass optimization"
set yrange [ 0 : 110 ] # noreverse nowriteback


set output 'bypass.eps'
plot 'table.dat' using  (100.0* ($3/$2)):xtic(1) title col

