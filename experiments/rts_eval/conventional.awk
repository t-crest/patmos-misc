#!/usr/bin/awk -f

BEGIN { FS=";"}
NR == 1 { next; }
{
  bench = $1 "/" $5;
  benches[bench]++;
  src = $4
  val = $6
}

$2 == "O1f" {
  if      (src == "trace") trace[bench] = val;
  else if (src == "platin") wcet[bench] = val;
  else if (src == "trace/platin") test[bench] = val;
}

END {
  for (b in benches) {
    printf("%s & %d & %d & %d \\\\ %% %.3f\n",
              b, wcet[b], test[b], trace[b], test[b] / trace[b])
  }
}
