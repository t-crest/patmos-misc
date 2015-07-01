#!/bin/bash

# collect all available information

# heading line
printf "%-16s  %10s  %10s  %10s  %10s  %10s\n" \
    bench cy_base cy_total dat_size pf_ok pf_ign

# all sim files
for f in *.sim; do
  bench=${f%%.*}
  dat_size=$(stat --format='%s' ${bench}.dat) # in bytes
  <${bench}.sim awk '
    # output of .stats TODO if they are more meaningful
    # (selected, single-path functions)

    # values from the python output .sim
    /CY_BASE/ { cy_base = $3 }
    /CY_MISS/ { cy_miss = $3 }
    /NO_MISS/ { no_miss = $3 }
    /PF_IGN/  { pf_ign  = $3 }
    /PF_OK/   { pf_ok   = $3 }

    END {
      printf "%-16s  %10d  %10d  %10d  %10d  %10d\n",
        "'${bench}'", cy_base, cy_base+cy_miss, '$dat_size', pf_ok, pf_ign
    }
  '
done

