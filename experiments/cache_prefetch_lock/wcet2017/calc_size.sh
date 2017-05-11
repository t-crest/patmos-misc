#!/bin/bash

INFILE=${1?No binary specified}
OUTFILE=${INFILE%.elf}.sizes

CACHE_SIZE=8192

if [[ ! -f "${INFILE}" ]]
then
  echo "File ${INFILE} does not exist!" >&2
  exit 1
fi


# we exclude functions from startup/teardown for the sum computed by awk.

# STATIC FOOTPRINT = sum of sizes of the executed functions
# Extract the sizes of the functions
# the strtonum() function works with gawk only.
join \
  <(pasim -G0 -m32M -V "${INFILE}" 2>&1 |\
    sed -n '/Profiling information:/,$ p' |\
    sed -n 's/\s*<\(.*\)>/\1/p' | sort -k 1b,1) \
  <(patmos-llvm-objdump -t "${INFILE}" |\
    grep -E "^[0-9a-f]{8} [gl]\s+F\s+.text" |\
    gawk '{print $6, strtonum("0x" $5)}' | sort -k 1b,1) |\
tee "${OUTFILE}" |\
grep -vwE "__call_exitprocs|exit|_exit|__fini|__init|__initreent|_malloc_r|memset|__register_exitproc|_start|__start" |\
if ! awk '{
       if ($2 > '${CACHE_SIZE}') {flag = 1}
       { total += $2 }
     }
     END {print total; if (flag == 1) exit 1}'
then
  echo "FUNCTION SIZE EXCEEDED CACHE SIZE!"
  exit 1
fi


# DYNAMIC FOOTPRINT for method cache
#pasim -G0 -m32M -V "${INFILE}" 2>&1 | \
#  sed -n '/Instruction Cache Statistics:/,/Data Cache Statistics:/ p' |\
#  grep -E "^\s+0x[0-9a-f]{8}" |\
#  awk '{total += $4} END {print total}'
