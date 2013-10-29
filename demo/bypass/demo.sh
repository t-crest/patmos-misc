#!/bin/bash

# current limitation: piping in commands does not work

echo patmos-clang-wcet -mconfig=config_ait.pml --wcet-guided-optimization --platin-wcet-options="--use-trace-facts --recorders g:lci --compute-criticalities" -o test test.c
read
patmos-clang-wcet -mconfig=config_ait.pml --wcet-guided-optimization --platin-wcet-options="--use-trace-facts --recorders g:lci --compute-criticalities" -o test test.c

