#!/bin/bash

LOG=$1
BINARY=$2

if [[ $BINARY != *.sp.elf ]]; then
  FILTER='sed -e s/_sp_//'
else
  FILTER=cat
fi

grep -Ef <(awk '/Reducing/ { print "\\<"$3"\\>" }' $1 | ${FILTER}) <(patmos-llvm-objdump -t $2) |\
awk '
  BEGIN {OFS="\t"; total = 0 }
  {
    funcsize = strtonum("0x"$5);
    total += funcsize;
    print $1, funcsize, $6;
  }
  END {
    print "Total:", total
  }'

