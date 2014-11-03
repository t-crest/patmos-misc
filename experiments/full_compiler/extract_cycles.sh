#!/bin/bash

WORK=work

for dir in `find $WORK -mindepth 1 -type d`; do
  echo $dir
  csv="${dir}.csv"

  echo -n > $csv
  for file in `(cd $dir; ls *wcet.txt)`; do
    bench=`echo $file | sed "s/-wcet.txt//" | sed "s/mrtc-//"`
    
    # extract trace cycles and combined cycles from files
    trace=`grep "trace" -A1 $dir/$file | grep "cycles" | sed "s/.*: \([0-9]*\).*/\1/"`
    wcet=`grep "combined" -A1 $dir/$file | grep "cycles" | sed "s/.*: \([0-9]*\).*/\1/"`
    misses=`grep "aiT" -A5 $dir/$file | grep "cache-misses-dcache" | sed "s/.*: \([0-9]*\).*/\1/"`
    hits=`grep "aiT" -A5 $dir/$file | grep "cache-hits-dcache" | sed "s/.*: \([0-9]*\).*/\1/"`
    if [ "$misses" == "" ]; then
      misses=0
    fi
    if [ "$hits" == "" ]; then
      hits=0
    fi

    echo $bench,$trace,$wcet,$hits,$misses >> $csv
  done
done
