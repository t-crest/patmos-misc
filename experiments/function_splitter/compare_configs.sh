#!/bin/bash

BASE=nosplit_ic4k_lru4

echo "# Suite, Benchname, Size, Reference, \"32/32\", \"128/128\", \"192/192\", \"256/256\", \"512/512\", \"1024/1024\""

for bench in `ls work/$BASE`; do
  name=${bench%.stats}
  suite=`echo "$name" | sed "s/-.*//"`
  benchname=`echo "$name" | sed "s/.*-//"`

  refcycles=`grep -m 1 "Cyc :" work/$BASE/$bench | sed "s/Cyc : *\([0-9]*\) */\1/"`
  size=`grep -m 1 "Bytes Transferred" work/nosplit_ic8m_lru/$bench | sed "s/   Bytes Transferred   : *\([0-9]*\) *\([0-9]\)*/\1/"`

#  if [ "$suite" != "mibench" ]; then
#    echo -n "# "
#  fi

  echo -n "\"$suite\", \"$benchname\", $size, $refcycles" 

  for i in 32 128 192 256 512 1024; do

    config="pref_sf_${i}_scc_${i}_mc4k_32_vb"
    
    cycles=`grep -m 1 "Cyc :" work/$config/$bench | sed "s/Cyc : *\([0-9]*\) */\1/"`
    
    echo -n ", $cycles"
      
  done

  echo
done

