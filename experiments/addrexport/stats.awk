#!/usr/bin/awk -f

#   1         2     3        4        5            6       7           8
# benchmark;build;analysis;source;analysis-entry;cycles;reads-stats;writes-stats
BEGIN {
  FS = ";"
  printf "%-50s  %10s  %10s  %10s  %20s  %20s  %20s  %20s  %10s\n",
         "benchmark", "trace",
         "wcet_no", "wcet_with",
         "memrd_no", "memrd_with",
         "memwr_no", "memwr_with",
         "%"
}
{
  if ($4 ~ "trace")           {
    trace[$1 "." $2 "." $3] = $6
  }
  if ($4 ~ "with-addresses/aiT")  {
    bench = $1 "." $2 "." $3
    wcet_with[bench] = $6
    memrd_with [bench] = $7
    memwr_with [bench] = $8
  }
  if ($4 ~ "no-addresses/aiT")    {
    bench = $1 "." $2 "." $3
    wcet_no[bench] = $6
    memrd_no [bench] = $7
    memwr_no [bench] = $8
  }
}
END {
    for (bench in trace) {
      perc = ""
      if (wcet_with[bench] < wcet_no[bench]) {
        perc = "(" wcet_with[bench] / wcet_no[bench] ")"
      }
      printf "%-50s  %10u  %10u  %10u  %20s  %20s  %20s  %20s  %10s\n",
             bench, trace[bench],
             wcet_no[bench], wcet_with[bench],
             memrd_no[bench], memrd_with[bench],
             memwr_no[bench], memwr_with[bench],
             perc
    }
}
