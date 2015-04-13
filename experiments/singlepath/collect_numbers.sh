#!/bin/bash

# collect numbers for the conventional (non inout) Malardalen benchmarks

function get_runtimes {
  for f in *.sp.sim; do
    local bench=${f%%.*}
    local rt="-"
    if [[ $(stat -c %s $f) > 0 ]]; then
      rt=$(tail -n1 $f | awk '{print $3}')
      [[ $rt =~ ^[0-9]+$ ]] || rt="-"
    fi
    echo $bench $rt
  done
}



function get_stats {
  for f in *.stats; do
    local bench=${f%%.*}
    if [[ $(stat -c %s $f) > 0 ]]; then
       gawk '
        /instructions inserted/ { inserted=$1 }
        /branch instructions removed/ { branchesrm=$1 }
        /spill bits/ { spillbits=$1 }
        /predicates for single-path/ { preds=$1 }
        /where S0 spill can be omitted/ { nospill=$1 }
        END {
          printf("%s %d %d %d %d %d\n", "'$bench'", preds, inserted, branchesrm, spillbits, nospill)
        }
       ' $f
    fi
  done
}

(
  echo "Benchmark  ET  #Pred  #Insrt  #BrRm  #SpillBits  #NoSpill"
  join <(get_runtimes | sort) <(get_stats | sort)
) | column -t
