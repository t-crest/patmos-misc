#!/usr/bin/awk -f
BEGIN {
  FS = ";"
  printf "%-50s  %10s  %10s  %6s\n",
         "benchmark", "unopt", "bypass", "%"
}
{
  if ($4 ~ "no-addresses/aiT") {
    bench = ($3) ? $1 "." $3 : $1
    unopt[bench] = $6
  }
  if ($4 ~ "bypass/aiT")  {
    bench = ($3) ? $1 "." $3 : $1
    bypass[bench] = $6
  }
}
END {
    for (bench in unopt) {
      printf "%-50s  %10d  %10d  %6.2f\n",
             bench, unopt[bench], bypass[bench],
             (100 * bypass[bench]) / unopt[bench]
    }
}
