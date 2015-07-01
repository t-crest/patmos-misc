#!/bin/bash

CMDOPTS="--blocksize=4"

for f in *.trace
do
  none=$(./sp_pflck.py ${CMDOPTS} --disable-lock --disable-prefetch $f)
  prefetch=$(./sp_pflck.py ${CMDOPTS} --disable-lock $f)
  prefetch_lock=$(./sp_pflck.py ${CMDOPTS} $f)
  echo $f $none $prefetch $prefetch_lock | \
    awk '{ print $1, $2, $3 " (" $3 / $2 ")", $4 " (" $4 / $2 ")" }'
done | column -t
