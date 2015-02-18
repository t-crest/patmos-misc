#!/bin/bash

SPROOTS=$(head -n1 sproots.txt)

rebuild=false
if [[ $# > 0 && $1 == "-B" ]]
then
  rebuild=true
else
  echo "Using existing results. Use '$0 -B' for a rebuild." >&2
fi

function extract_sim {
  local infile=$1
  for root in ${SPROOTS}; do
    grep -A2 ${root} ${infile} | tail -n1 | \
      awk '{ print "'${root}'", $2, $3 }'
  done | sort
}

function extract_wcet {
  local infile=$1
  local src=$2
  awk '
    BEGIN { root = ""; source = ""; }
    /analysis-entry:/ { root = $3; next; }
    /\ssource:/ { source = $2; next; }
    /\scycles:/ {
      cycles = $2;
      if (source == "'${src}'") {
        print root, cycles;
      }
      next;
    }
  ' < ${infile} | sort
}


CONFIGS="ideal dcideal"
TARGETS="debie1.sim debie1.wcet.pml debie1.sp.sim debie1.times debie1.stats"

for conf in ${CONFIGS}
do
  resultdir=results_${conf}

  if ${rebuild}
  then
    # maybe rebuilding the .elf files is unnecessary?
    make clean
    make ${TARGETS} "ARCHPML=config_${conf}.pml"

    mkdir -p ${resultdir}
    cp ${TARGETS} ${resultdir}
  fi

  outfile=result_${conf}.txt
  echo "Writing '${outfile}'" >&2
  echo "Task ConvMin ConvMax ConvWCET SPMin SPMax" > ${outfile}
  join <(join <(extract_sim ${resultdir}/debie1.sim) <(extract_wcet ${resultdir}/debie1.wcet.pml platin)) <(extract_sim ${resultdir}/debie1.sp.sim) >> ${outfile}
done


#LAST_MOD_TIME=$(stat --format="%Y" ${REPORT})
#if [ -f ${REPORT} ]
#then
#  echo Backup report last modified on $(date --date="@${LAST_MOD_TIME}")
#  mv ${REPORT} ${REPORT}.${LAST_MOD_TIME}
#fi

