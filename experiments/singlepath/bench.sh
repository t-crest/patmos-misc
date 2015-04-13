#!/bin/bash


BENCHMARKS="bs bsort100 cnt compress cover crc expint fac fdct"


function simlines {
  local config=$1
  local bench=$2
  awk '
    BEGIN { ns = 0; OFS="\t" }
    $1 ~ /<.*>/ { name = substr($1,2,length($1)-2); ns = 1; next; }
    {
      if (ns == 1) { ns = 2; next; }
      if (ns == 2) {
        ns = 0;
        print "'${config}'", "'${bench}'/" name, $2, $3, $4;
        next;
      }
    }
  '
}

function wcetlines {
  local config=$1
  local bench=$2
  local src=$3
  awk '
    BEGIN { entry = ""; source = ""; OFS="\t" }
    /analysis-entry:/ { entry = $3; next; }
    /\ssource:/ { source = $2; next; }
    /\scycles:/ {
      cycles = $2;
      if (source == "'${src}'") {
        print "'${config}'", "'${bench}'/" entry, cycles;
      }
      next;
    }
  '
}

function analysis_source {
  local config=$1
  case "${config}" in
  ait)  echo "combined" ;;
  data) echo "platin" ;;
  ideal)    echo "platin" ;;
  esac
}

function pml_config {
  local config=$1
  echo "config/config_${config}.pml"
}

for config in ideal ait data
do
  summary_sim=summary-sim-${config}.txt
  summary_sim_sp=summary-sim-${config}-sp.txt
  summary_wcet=summary-wcet-${config}.txt
  summary_wcet_sp=summary-wcet-${config}-sp.txt
  rm -f ${summary_sim} ${summary_sim_sp}
  rm -f ${summary_wcet} ${summary_wcet_sp}

  for bench in ${BENCHMARKS}
  do
    make ${bench}.clean
    make ${bench}.sim PMLCONFIG=$(pml_config ${config})
    simlines ${config} ${bench} < ${bench}.sim >> ${summary_sim}
    make ${bench}.wcet PMLCONFIG=$(pml_config ${config})

    wcetlines ${config} ${bench} $(analysis_source ${config}) < ${bench}.wcet >> ${summary_wcet}

    make ${bench}.sp.clean
    make ${bench}.sp.sim PMLCONFIG=$(pml_config ${config})
    simlines ${config}-sp ${bench} < ${bench}.sp.sim >> ${summary_sim_sp}
    #make ${bench}.sp.wcet PMLCONFIG=$(pml_config ${config})
    #wcetlines ${config}-sp ${bench} $(analysis_source ${config}) < ${bench}.sp.wcet >> ${summary_wcet_sp}
  done
done

source table.cmd
