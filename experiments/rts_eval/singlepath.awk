#!/usr/bin/awk -f

BEGIN { FS=";"; OFS=" & "; OFMT="%.3f"; ORS=" \\\\\n"}

NR == 1 { next }

{
  bench = $1 "/" $5;
  benches[bench]++;
  src = $4
  maxc = $6
  minc = $7
}

/O1f\-sp/ {
  if (src == "trace") {
    if (maxc != minc) {
      print "Error: min!=max"
      exit 1
    }
    sp[bench] = maxc;
  }
}

/O1f[^-]/ {
  if (src == "trace") {
    c_min[bench] = minc;
    c_max[bench] = maxc;
  }
  else if (src == "platin") {
    c_wcet[bench] = maxc;
  }
}

END {
  for (b in benches) {
    print b , c_wcet[b], "[" c_min[b] "," c_max[b] "]", sp[b], sp[b]/c_wcet[b]
  }
}
