set terminal svg size 600,400 dynamic enhanced fname 'arial'  fsize 10 mousing name "mem_accesses" butt solid 
set boxwidth 0.9 absolute
set style fill   solid 1.00 border lt -1
set key inside right top vertical Right noreverse noenhanced autotitles nobox
set style histogram rowstacked gap 1 title  offset character 0, 0, 0
set datafile missing '-'
set style data histograms
set xtics border in scale 0,0 nomirror rotate by -45  offset character 0, 0, 0 autojustify
set xtics  norangelimit font ",8"
set xtics   ()
set title "Memory accesses as classified by aiT"
#set yrange [ 0.00000 : 300000. ] noreverse nowriteback


set output 'rd_no.O0.svg'
plot 'access_types.O0.dat' using  3:xtic(1) title col, \
                        '' using  4         title col, \
                        '' using  5         title col, \
                        '' using  6         title col

set output 'rd_with.O0.svg'
plot 'access_types.O0.dat' using  8:xtic(1) title col, \
                        '' using  9         title col, \
                        '' using 10         title col, \
                        '' using 11         title col
set output 'wr_no.O0.svg'
plot 'access_types.O0.dat' using 13:xtic(1) title col, \
                        '' using 14         title col, \
                        '' using 15         title col, \
                        '' using 16         title col

set output 'wr_with.O0.svg'
plot 'access_types.O0.dat' using 18:xtic(1) title col, \
                        '' using 19         title col, \
                        '' using 20         title col, \
                        '' using 21         title col




set output 'rd_no.O1.svg'
plot 'access_types.O1.dat' using  3:xtic(1) title col, \
                        '' using  4         title col, \
                        '' using  5         title col, \
                        '' using  6         title col

set output 'rd_with.O1.svg'
plot 'access_types.O1.dat' using  8:xtic(1) title col, \
                        '' using  9         title col, \
                        '' using 10         title col, \
                        '' using 11         title col
set output 'wr_no.O1.svg'
plot 'access_types.O1.dat' using 13:xtic(1) title col, \
                        '' using 14         title col, \
                        '' using 15         title col, \
                        '' using 16         title col

set output 'wr_with.O1.svg'
plot 'access_types.O1.dat' using 18:xtic(1) title col, \
                        '' using 19         title col, \
                        '' using 20         title col, \
                        '' using 21         title col



set output 'rd_no.O2.svg'
plot 'access_types.O2.dat' using  3:xtic(1) title col, \
                        '' using  4         title col, \
                        '' using  5         title col, \
                        '' using  6         title col

set output 'rd_with.O2.svg'
plot 'access_types.O2.dat' using  8:xtic(1) title col, \
                        '' using  9         title col, \
                        '' using 10         title col, \
                        '' using 11         title col
set output 'wr_no.O2.svg'
plot 'access_types.O2.dat' using 13:xtic(1) title col, \
                        '' using 14         title col, \
                        '' using 15         title col, \
                        '' using 16         title col

set output 'wr_with.O2.svg'
plot 'access_types.O2.dat' using 18:xtic(1) title col, \
                        '' using 19         title col, \
                        '' using 20         title col, \
                        '' using 21         title col
