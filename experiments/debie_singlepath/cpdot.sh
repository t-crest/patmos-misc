#!/bin/bash
#
# This script is intended to be used in concunction with LLVM's viewCFG()
# method for Function and MachineFunction.
# It reads line by line from from stdin and captures the line
#   Writing '/tmp/XXX.dot)'
# It copies the dot file and kills the dotty process spawned by LLVM.
#


fname=${1?"USAGE: $0 <fname>"}

re_file="^Writing '(/tmp/.*\.dot)'"

while read line
do
  if [[ ${line} =~ ${re_file} ]]; then
    tmpfile=${BASH_REMATCH[1]}
    target="${fname}.$(basename ${tmpfile/-[0-9a-f]*.dot/.dot})"
    #echo "-> ${target}" >&2
    cp ${tmpfile} ${target}
    sleep 1
    pid=$(ps ax | grep -v grep | grep  ${tmpfile} | cut -c1-5)
    if [ -n "${pid}" ]; then
      kill ${pid}
    fi
  fi
done

