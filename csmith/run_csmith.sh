#!/bin/bash

CSMITH_HOME=/home/stefan/share/csmith

if [ "$1" == "clean" ]; then
  rm -f test.c test.O*.* log.O*.* platform.info
  exit
fi

# Stop on first error
set -e

success=0

while true; do

  echo "# Generating C program"
  csmith > test.c

  echo "# Compiling with clang -O0"
  clang -o test.O0.host -I${CSMITH_HOME}/runtime -O0 -w test.c

  echo "# Compiling with clang -O2"
  clang -o test.O2.host -I${CSMITH_HOME}/runtime -O2 -w test.c

  echo "# Compiling with patmos-clang -O0"
  patmos-clang -o test.O0.patmos -I${CSMITH_HOME}/runtime -O0 -w test.c

  echo "# Compiling with patmos-clang -O2"
  patmos-clang -o test.O2.patmos -I${CSMITH_HOME}/runtime -O2 -w test.c

  echo "# Running test with -O0 on host"
  ./test.O0.host > log.O0.host

  echo "# Running test with -O2 on host"
  ./test.O0.host > log.O2.host
  
  echo "# Running test with -O0 on pasim"
  pasim -q test.O0.patmos > log.O0.patmos
  
  echo "# Running test with -O0 on pasim"
  pasim -q test.O0.patmos > log.O2.patmos
  
  echo "# Checking for differences at -O0"
  diff log.O0.host log.O0.patmos > /dev/null

  echo "# Checking for differences at -O2"
  diff log.O2.host log.O2.patmos > /dev/null

  let success=success+1

  echo "# Finished!"
  echo "Successfull compilations: $success"
  echo

done

