#!/bin/bash
#
# Author: Stefan Hepp <stefan@stefant.org>
# 
# Compile benchmarks and collect function splitter statistics.
# 

###### Configuration Start #######

BENCH_SRC_DIR=../../../../patmos-benchmarks
BENCH_BUILD_DIR=build
WORK_DIR=work
PARJ=-j1

# Quick hack to make the test distributed over multiple hosts
NUM_HOSTS=1
HOST_ID=0

CLANG_ARGS="-w"
CMAKE_ARGS="-DCMAKE_TOOLCHAIN_FILE=$BENCH_SRC_DIR/cmake/patmos-clang-toolchain.cmake -DENABLE_CTORTURE=false -DENABLE_EMULATOR=false -DENABLE_TESTING=true -DPLATIN_ENABLE_WCET=false -DENABLE_STACK_CACHE_ANALYSIS_TESTING=false -DENABLE_C_TESTS=false -DENABLE_MEDIABENCH=false"
MCACHE_IDEAL="-M fifo -m 8m --mcmethods=512 --psize=1k"

MAX_FUNCTION_SIZE=2040

###### Configuration End ########

if [ -f run.cfg ]; then
  . run.cfg
fi

# only works on single-thread
PARJ=-j1

# Exit on first error
set -e

function config_bench() {
  local pasim_args=$1
  local clang_args=$2

  mkdir -p $BENCH_BUILD_DIR
  (cd $BENCH_BUILD_DIR && cmake $CMAKE_ARGS -DCMAKE_C_FLAGS="$CLANG_ARGS $clang_args" -DPASIM_EXTRA_OPTIONS="$pasim_args" $BENCH_SRC_DIR)
}

function build_bench() {
  (cd $BENCH_BUILD_DIR && make clean && make $PARJ)
}

function run_bench() {
  local testname=$1

  (cd $BENCH_BUILD_DIR && make ARGS="$PARJ" test)

  mkdir -p $WORK_DIR/$testname

  # collect .stats files
  find $BENCH_BUILD_DIR -iname "*.stats" -exec cp -f {} $WORK_DIR/$testname \;
}


last_clang_args="none"
current_clang_args=
host_cnt=0

function collect_splitter() {
  local testname=$1
  local prefsize=$2
  local sccsize=$3
  
  fsplit_options="-Xllc -mpatmos-split-call-blocks=false -mpatmos-max-subfunction-size=$MAX_FUNCTION_SIZE -mpatmos-preferred-subfunction-size=$prefsize -mpatmos-preferred-scc-size=$sccsize"

  csv=`readlink -f "$WORK_DIR/splitter_${testname}.csv"`

  echo
  echo "**** Running configuration $testname ****"
  echo

  rm -f $csv

  config_bench "$MCACHE_IDEAL" "$fsplit_options -Xllc -mpatmos-function-splitter-stats=$csv -Xllc -mpatmos-function-splitter-stats-append"

  build_bench

#  cat $csv | sort > $WORK_DIR/splitter_${testname}_sorted.csv
#  rm -f $csv
}


# Check influence of function splitter
for i in 32 64 128 256 512 1024 384 192 96 320 448; do
  #for scc in $i 1024 2048; do
  for scc in $i 2048; do
    collect_splitter "pref_sf_${i}_scc_${scc}" $i $scc
  done
done
