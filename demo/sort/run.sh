#!/bin/bash

mkdir -p tmp

platin pml-config --target patmos-unknown-unknown-elf -o config.pml -m 2k -M fifo8 

patmos-clang `platin tool-config -i config.pml -t clang` -O2 -o sort -mserialize=sort.pml sort.c

platin wcet -i config.pml --enable-trace-analysis --enable-wca -b sort -i sort.pml --outdir tmp --report

