#!/bin/bash

WORK_DIR=work
BENCH=mrtc-fft1
PREF_SIZE=256

if [ ! -z "$1" ]; then
  BENCH=$1
fi


for size in 1 4 8 16; do
  echo "    \\hline"
  for fn in 8 16 32 64 "ideal"; do
    statfile=$WORK_DIR/pref_sf_${PREF_SIZE}_scc_${PREF_SIZE}_mc${size}k_${fn}/${BENCH}.stats
    fbfile=$WORK_DIR/pref_sf_${PREF_SIZE}_scc_${PREF_SIZE}_mc${size}k_${fn}_fb/${BENCH}.stats
    lrufile=$WORK_DIR/pref_sf_${PREF_SIZE}_scc_${PREF_SIZE}_mc${size}k_${fn}_lru/${BENCH}.stats

    if [ ! -e $statfile -o ! -e $fbfile -o ! -e $lrufile ]; then
      continue
    fi
    
    hits=`grep "Cache Hits" $statfile  | sed "s/.*: *\([0-9]*\)/\1/"`
    miss=`grep "Cache Misses" $statfile  | sed "s/.*: *\([0-9]*\)/\1/"`

    hitrate=`echo "scale=2;(100*$hits)/($hits+$miss)" | bc`

    hits=`grep "Cache Hits" $fbfile  | sed "s/.*: *\([0-9]*\)/\1/"`
    miss=`grep "Cache Misses" $fbfile  | sed "s/.*: *\([0-9]*\)/\1/"`

    hitrate_fb=`echo "scale=2;(100*$hits)/($hits+$miss)" | bc`

    hits=`grep "Cache Hits" $lrufile  | sed "s/.*: *\([0-9]*\)/\1/"`
    miss=`grep "Cache Misses" $lrufile  | sed "s/.*: *\([0-9]*\)/\1/"`

    hitrate_lru=`echo "scale=2;(100*$hits)/($hits+$miss)" | bc`

    mc_cycles=`grep "Miss Stall Cycles" $statfile | sed "s/.*: *\([0-9]*\) .*/\1/"`
    fb_cycles=`grep "Miss Stall Cycles" $fbfile   | sed "s/.*: *\([0-9]*\) .*/\1/"`
    lru_cycles=`grep "Miss Stall Cycles" $lrufile   | sed "s/.*: *\([0-9]*\) .*/\1/"`

    fb_ratio=`echo "scale=3;($mc_cycles/$fb_cycles)" | bc | sed "s/^\./0./"`
    lru_ratio=`echo "scale=3;($lru_cycles/$fb_cycles)" | bc | sed "s/^\./0./"`

    echo "    $size K & $fn & $hitrate_fb \\% & $hitrate \\% & $hitrate_lru \\% & $fb_ratio  & $lru_ratio \\\\"
  done
done

