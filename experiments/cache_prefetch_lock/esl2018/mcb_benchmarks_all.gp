set terminal pdf size 6.5,2.2 font ",9" enhanced color
set output "sp_pc_mc.pdf"
set xtics nomirror rotate by -45
set ylabel "Relative performance"
set key horiz center above
#set key spacing 0.85 font ",10" 
#set key title "cache size:"
set border 3
set grid ytics
set ytics 0.5
set yrange [0:3.5]
set grid mytics
set ytics nomirror
set mytics 5
set arrow from -0.25,1 to 30.36,1 nohead lc rgb "red" lw 2 front
set style data histogram
set style fill solid border -1
set style histogram clustered gap 2 
plot for [COL=2:5] "data2.dat" using COL:xticlabels(1) title columnheader(COL)
