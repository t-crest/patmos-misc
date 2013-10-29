#!/bin/bash

file=$1
if [ -z $file ]; then
  file="test"
fi

options="--compute-criticalities"

echo patmos-clang-wcet -mconfig=config_ait.pml --wcet-guided-optimization --platin-wcet-options="--use-trace-facts --recorders g:lci $options" -o $file $file.c -save-temps
echo -n "[Press enter to execute]"
read
patmos-clang-wcet -mconfig=config_ait.pml --wcet-guided-optimization --platin-wcet-options="--use-trace-facts --recorders g:lci $options" -o $file $file.c -save-temps

