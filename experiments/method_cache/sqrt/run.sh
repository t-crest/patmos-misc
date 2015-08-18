#!/bin/bash
PASIM_OPTS="--print-stats main"
PLATIN_OPTS="--enable-wca --disable-ait --use-trace-facts"

mkdir -p tmp

for opt in "" "--mcmethods 32" "-m 2k" "-C icache -K dm" "-C icache -K lru2" "-C icache -K lru4" "-C icache -K lru8"; do 
  echo "** pasim $opt:"
  for i in sqrt sqrt.nosc sqrt.ps512 sqrt.nosc.ps512 sqrt.ps768 sqrt.nosc.ps768 sqrt.nops sqrt.nosc.nops; do 
    if [ "$1" == "-v" ]; then
      echo "pasim -v $PASIM_OPTS $opt $i" >&2
    fi
    echo -n "$i "
    pasim -v $PASIM_OPTS `echo $opt` $i 2>&1 | grep "Cycles:"
  done | column -t
done 

for opt in "" "-M fifo32" "-m 2k" "-M fifo32 -D ideal" "-C icache -M dm" "-C icache -M lru2" "-C icache -M lru4" "-C icache -M lru8"; do
  echo "** platin $opt:"
  if [ "$1" == "-v" ]; then
    echo "platin pml-config -o config.pml --target patmos-unknown-unknown-elf $opt" >&2
  fi
  platin pml-config -o config.pml --target patmos-unknown-unknown-elf `echo $opt`
  for i in sqrt sqrt.nosc sqrt.ps512 sqrt.nosc.ps512 sqrt.ps768 sqrt.nosc.ps768 sqrt.nops sqrt.nosc.nops; do 
    if [ "$1" == "-v" ]; then
      echo "platin wcet -b $i -i ${i}.pml -i config.pml $PLATIN_OPTS --report report.txt" >&2
    fi
    echo -n "$i "
    platin wcet -b $i -i ${i}.pml -i config.pml $PLATIN_OPTS --report report.txt 2>/dev/null
    sim=`cat report.txt | grep -A 1 trace | grep cycles | sed "s/ *cycles: *//"`
    wcet=`cat report.txt | grep -A 1 platin | grep cycles | sed "s/ *cycles: *//"`
    ratio=`echo "scale=2; $wcet / $sim" | bc`
    echo " Cycles: $sim $wcet $ratio"
  done | column -t
done
