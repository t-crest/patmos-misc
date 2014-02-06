#!/bin/sh

# Get a CSV of all benchmark sizes

for i in `ls work/ideal`; do
  name=${i%.stats}
  suite=`echo "$name" | sed "s/-.*//"`
  bench=`echo "$name" | sed "s/.*-//"`
  size=`grep -m 1 "Bytes Transferred" work/ideal/$i | sed "s/work\/ideal\///" | sed "s/   Bytes Transferred   : *\([0-9]*\) *\([0-9]\)*/\1/"`
  cycles=`grep -m 1 "Cyc :" work/ideal/$i | sed "s/work\/ideal\///" | sed "s/Cyc : *\([0-9]*\) */\1/"`
  func=`grep -m 1 "Max Methods in Cache" work/ideal/$i | sed "s/work\/ideal\///" | sed "s/   Max Methods in Cache: *\([0-9]*\) */\1/"`
  

  echo "$suite, $bench, $size, $func, $cycles"
done
