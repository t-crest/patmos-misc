
for config in ideal ait data
do
echo ---
#join <(join <(sort -k2 summary-sim-${config}.txt) <(sort -k2 summary-wcet-${config}.txt) -j2) \
#     <(join <(sort -k2 summary-sim-${config}-sp.txt) <(sort -k2 summary-wcet-${config}-sp.txt) -j2) | column -t
join -1 1 -2 2 <(join <(sort -k2 summary-sim-${config}.txt) <(sort -k2 summary-wcet-${config}.txt) -j2) \
     <(sort -k2 summary-sim-${config}-sp.txt)  | awk '
     function get_intv(mn, mx) {
        return (mn != mx) ? "[" mn ", " mx "]" : mx;
     }
     {
        print $1" & $["$3", "$4"]$ & $"$7"$ & $"get_intv($9, $10)"$ \\\\"
     }
     ' | column -t
done

