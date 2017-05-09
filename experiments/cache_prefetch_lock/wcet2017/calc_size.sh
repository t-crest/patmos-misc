#!/bin/bash -x

INFILE=${1?No binary specified}
OUTFILE=${INFILE%.elf}.size

if [[ ! -f "${INFILE}" ]]
then
  echo "File ${INFILE} does not exist!" >&2
  exit 1
fi


if [[ "${INFILE}" =~ \.nofs\. ]]
then
  # Extract the sizes of the functions
  # the strtonum() function works with gawk only.
  join \
    <(pasim -G0 -m32M -V "${INFILE}" 2>&1 |\
      sed -n '/Profiling information:/,$ p' |\
      sed -n 's/\s*<\(.*\)>/\1/p' | sort) \
    <(patmos-llvm-objdump -t "${INFILE}" |\
      grep -E "^[0-9a-f]{8} [gl]\s+F\s+.text" |\
      gawk '{print $6, strtonum("0x" $5)}' | sort) |\
  awk '{
         if ($2 > 16384) {print "SIZE EXCEEDS"; print; exit 1}
         { total += $2 }
       }
       END {print total}'
else
  pasim -G0 -m32M -V "${INFILE}" 2>&1 | \
    sed -n '/Instruction Cache Statistics:/,/Data Cache Statistics:/ p' |\
    grep -E "^\s+0x[0-9a-f]{8}" | \
    awk '{total += $4} END {print total}'
fi
