#!/bin/bash
if [ "$1" == "clean" ]; then
    rm -f *.log *.xml *.pml *.ais *.apx jumptable 
    exit
fi

set -x

patmos-clang -o jumptable -mpatmos-serialize=jumptable.pml -mpatmos-serialize-skip-instructions jumptable.c 
#../patmos-llvm/tools/psk/psk-merge -o jumptable.pml jumptable.pml
../patmos-llvm/tools/psk/psk-pml2ais -g -a jumptable.apx -b jumptable -r report.log -x results.xml -e measure -o jumptable.ais jumptable.pml
pasim -q jumptable
a3patmos -b jumptable.apx
