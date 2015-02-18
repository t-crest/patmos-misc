#!/usr/bin/gawk -f
{
  if (NR == 1) {
    print $0, "Ratio"
  } else {
    print $0, $6 / $4
  }
}
