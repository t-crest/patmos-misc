cat eval_bypass_2k_datacache.csv \
  | grep -v ^tests \
  | sed -e 's/mrtc_/mrtc./g' -e 's/main//g' -e 's/_fbw//g' -e 's/_task//g' -e 's/_minimal//g' -e 's|_|-|g' \
  | gawk -f bypass.awk > table.tmp

head -n 1 table.tmp > table.txt
tail -n +2 table.tmp | sort >> table.txt
rm table.tmp



cat table.txt  | tr -s ' ' | cut -d' ' -f1-4 > table.dat

gnuplot plot.p
epstopdf bypass.eps
