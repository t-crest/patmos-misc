#!/bin/bash
#
# Small utility script to get the size of extended basic blocks out of a pasim trace.
# It will print the size of each continiously executed block of code.
#
# TODO port to python (?)
#
# Usage: pasim <binary> --debug=0 --debug-fmt=trace | ./get_ebb_size.sh
#
# Author: Stefan Hepp <stefan@stefant.org>
#

startpc=
lastpc=1

while read pc cnt; do
  pc=$((0x$pc))
  nextpc=$((lastpc + 8))

  if [[ (($pc < $lastpc)) || (($pc > $nextpc)) ]]; then
    if [ "$startpc" ]; then
      echo $((nextpc-startpc))
    fi
    startpc=$pc
  fi
  lastpc=$pc
done
