#!/bin/bash

WORK_DIR=work
RESULT_DIR=results
BENCH=mrtc-fft1
PREF_SIZE=256

if [ ! -z "$1" ]; then
  PREF_SIZE=$1
fi


for size in 1 4 8 16 32; do
  echo "        \\hline"
  for fn in 8 16 32 64 "ideal"; do
    statfile=$WORK_DIR/pref_sf_${PREF_SIZE}_scc_${PREF_SIZE}_mc${size}k_${fn}/${BENCH}.stats
    vbfile=$WORK_DIR/pref_sf_${PREF_SIZE}_scc_${PREF_SIZE}_mc${size}k_${fn}_vb/${BENCH}.stats
    icfile=$WORK_DIR/pref_sf_${PREF_SIZE}_scc_${PREF_SIZE}_ic${size}k_lru4/${BENCH}.stats

    if [ ! -e $statfile -o ! -e $vbfile -o ! -e $icfile ]; then
      continue
    fi
    
    hitrate=`grep -m 1 "Cache Hits" $statfile  | sed "s/.*: *[0-9]* *\([0-9.]*\)%/\1/"`
    missrate=`grep -m 1 "Cache Misses" $statfile  | sed "s/.*: *[0-9]* *\([0-9.]*\)%/\1/"`

    util=`grep -m 1 "Utilization" $statfile | sed "s/.*: *\([0-9]*\.[0-9]*\).*/\1/"`

    max_methods=`grep -m 1 "Max Methods in Cache" $statfile | sed "s/.*: *\([0-9]*\)/\1/"`
    mc_cycles=`grep -m 1 "Miss Stall Cycles" $statfile | sed "s/.*: *\([0-9]*\) .*/\1/"`
    vb_cycles=`grep -m 1 "Miss Stall Cycles" $vbfile   | sed "s/.*: *\([0-9]*\) .*/\1/"`

    ic_misses=`grep -m 1 "Reads " $icfile | head -n 1 | sed "s/.*: *[0-9]* *[0-9]* *\([0-9]*\) .*/\1/"`
    
    ic_fb=`echo "scale=3;$mc_cycles/($ic_misses * 7)" | bc | sed "s/^\./0\./"`
    ic_vb=`echo "scale=3;$vb_cycles/($ic_misses * 7)" | bc | sed "s/^\./0\./"`

#    echo "        $size K & $fn & $hitrate \\% & $util \\% & $ic_fb & $ic_vb \\\\"
    echo "        $size K & $fn & $hitrate \\% & $mc_cycles & $util \\% & $max_methods \\\\"
  done
done

