#!/bin/bash

function copy_stats {
  for f in ./build/O{0,1,2}/build.*.log
  do
    STAT=$(grep -E "\<pml-export\>" $f)
    if [ $? == 0 -a ! -f ${f%.*}.stats ]
    then
      echo ${STAT} > ${f%.*}.stats
    fi
  done
}

function get_num_exports {
  for f in ./build/O{0,1,2}/build.*.stats
  do
    STAT=$(grep -E "exported load" $f)
    if [ $? == 0 ]
    then
      NUM_EXPORT=$(echo ${STAT} | tr -s "[:space:]" "\t" | cut -f1)
      echo $(echo $f | tr -s "/." "  " | cut -d' ' -f3,5) ${NUM_EXPORT}
    fi
  done | awk '
    BEGIN {
        printf "%-30s  %3s  %3s  %3s\n",
          "benchmark", "-O0", "-O1", "-O2"
    }
    /^O0/ { benchmarks[$2]; O0[$2] = $3 }
    /^O1/ { benchmarks[$2]; O1[$2] = $3 }
    /^O2/ { benchmarks[$2]; O2[$2] = $3 }
    END {
      for (bench in benchmarks) {
        printf "%-30s  %3d  %3d  %3d\n",
          bench, O0[bench], O1[bench], O2[bench]
      }
    }'
}

function report {
  awk -f ./stats.awk < work/report.csv | sort
}

function access_types {
  # memrd_no  memrd_with  memwr_no  memwr_with
  # total/exact/nearly/imprecise/unknown
  for o in O1
  do
    outfile=access_types.${o}.dat
    echo benchmark \
      ld_no_total ld_no_exact ld_no_nearly ld_no_imprecise ld_no_unknown \
      ld_with_total ld_with_exact ld_with_nearly ld_with_imprecise ld_with_unknown \
      st_no_total st_no_exact st_no_nearly st_no_imprecise st_no_unknown \
      st_with_total st_with_exact st_with_nearly st_with_imprecise st_with_unknown \
      > ${outfile}
    report | grep .${o}f. | sed -e "s;////;0/0/0/0/0;g" | tr -s "[:space:]" | \
      cut -d' ' -f 1,5-8 | tr '/' ' ' | \
      sed -e 's/\.O1f\.main_minimal//g' | \
      sed -e 's/fbw\.O1f\.//g' -e 's/_minimal//g' | \
      sed -e 's/^mrtc_/mrtc./g' -e 's/^papa_/papa./g' | \
      sed -e 's/_/-/g' | \
      grep -v nsichneu | grep -v ^tests- >> ${outfile}

      sed -i -e 's/ld_with_//g' -e 's/ld_no_//g' ${outfile}
  done
}

      #sed -e 's/^.\+_\(.*\)\.'${o}'\.\(.*\)_minimal/\1.\2/' | \

#copy_stats

report

#get_num_exports

access_types

gnuplot plot.p
