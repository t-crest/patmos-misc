#!/bin/bash

WORK_DIR=work
RESULT_DIR=results

# Make a table that compares split-call-blocks=false/true per configuration for all benchmarks

# Print header
benchmarks=
for f in `ls $WORK_DIR/ideal`; do
  echo -n ",\"${f/.stats/}\""
  benchmarks="$benchmarks $f"
done
echo

# Collect configurations
for dir in `ls $WORK_DIR`; do
  nocbb="${dir/_cbb/}"
  
  if [ "$dir" == "$nocbb" ]; then
    continue
  fi

  if [ ! -d $WORK_DIR/$nocbb ]; then
    continue
  fi

  echo -n "$dir"

  for b in $benchmarks; do
    cbb_cycles=`sed -n '2s/Cyc : //p' $WORK_DIR/$dir/$b`
    nocbb_cycles=`sed -n '2s/Cyc : //p' $WORK_DIR/$nocbb/$b`
    
    cbb_cycles="${cbb_cycles/Cyc : /}"
    nocbb_cycles="${nocbb_cycles/Cyc : /}"

    ratio=`echo "scale=5;$cbb_cycles/$nocbb_cycles" | bc`

    echo -n ",$ratio"
  done

  echo

done

