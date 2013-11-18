#!/bin/bash

# TODO port this to ruby, integrate with the testing framework

BENCH_SRC_DIR=../../../../patmos-benchmarks
BENCH_BUILD_DIR=build
WORK_DIR=work

CMAKE_ARGS="-DCMAKE_TOOLCHAIN_FILE=$BENCH_SRC_DIR/cmake/patmos-clang-toolchain.cmake -DENABLE_CTORTURE=false -DENABLE_EMULATOR=false -DENABLE_TESTING=true -DPLATIN_ENABLE_WCET=false -DENABLE_STACK_CACHE_ANALYSIS_TESTING=false -DENABLE_C_TESTS=false -DENABLE_MEDIABENCH=false"
PASIM_ARGS="-S dcache"

# Exit on first error
set -e

function config_bench() {
  local pasim_args=$1
  local clang_args=$2

  mkdir -p $BENCH_BUILD_DIR
  (cd $BENCH_BUILD_DIR && cmake $CMAKE_ARGS -DCMAKE_C_FLAGS="-w $clang_args" -DPASIM_OPTIONS="$pasim_args" $BENCH_SRC_DIR)
}

function build_bench() {
  (cd $BENCH_BUILD_DIR && make clean && make -j4)
}

function run_bench() {
  local testname=$1

  (cd $BENCH_BUILD_DIR && make ARGS="-j4" test)

  mkdir -p $WORK_DIR/$testname

  # collect .stats files
  find $BENCH_BUILD_DIR -iname "*.stats" -exec cp -f {} $WORK_DIR/$testname \;
}

function collect_stats() {
  local testname=$1
  local pasim_args=$2
  local clang_args=$3

  if [ ! -d $WORK_DIR/$testname ]; then
    echo
    echo "**** Running configuration $testname ****"
    echo

    config_bench "$pasim_args" "$clang_args"

    if [ ! -z "$clang_args" ]; then
      build_bench
    fi

    run_bench $testname
  else
    echo
    echo "**** Skipping configuration $testname ****"
    echo
  fi
}


#for pasim in -G 0 -M fifo -m 8m --mcmethods=512; # ideal cache, determine max. code size, code blocks, overhead of
#                                                   splitting, utilisation
#             -G 9 -M fifo -m 4k --mcmethods=512; # ideal assoc, determine preferred size, determine max required assoc
#             -G 9 -M fifo -m 1k --mcmethods=512; # -- "" --
#             -G 9 -M fifo -m 4k --mcmethods=4, 8, 16, 32  # Determine cost of lower assoc; fix function splitter setup
#             -G 9 -M fifo -m 1k --mcmethods=4, 8, 16      # -- "" --
#  for preferred-subfunction-size=64, 96, 128, 192, 256, 320, 384, 448, 512, max-subfunction-size=1024, -mpatmos-split-call-blocks=true|false;
#    for bench in .. :
#      - cached code size: = bytes allocated
#      - # code blocks: = max methods in cache
#      - # cache blocks @ 256 B blocks: =
#      - Cycles: -> up with smaller splitting
#      - Utilisation: -> down with smaller splitting


# Ideal cache, no splitting; determine max. code size, reference for other runs
collect_stats "ideal" "-G 0 -M fifo -m 8m --mcmethods=512" "-mpatmos-disable-function-splitter"

# Check influence of max-SF-size: ideal cache, fixed overhead for regions, split BBs
for i in 8192 4096 2048 1024 512 256; do
  collect_stats "max_sf_$i" "-G 0 -M fifo -m 8m --mcmethods=512" "-mpatmos-method-cache-size=$i -mpatmos-split-call-blocks=false -mpatmos-preferred-subfunction-size=256"
done

# Check influence of function splitter
for i in 1024 512 384 256 192 96 32 320 64 448; do
  collect_stats "pref_sf_${i}_ideal" "-G 0 -M fifo -m 8m --mcmethods=512" "-mpatmos-split-call-blocks=false -mpatmos-preferred-subfunction-size=$i"

  for j in "4k" "2k" "1k"; do

    # Determine preferred size, determine max required assoc: use ideal assoc, fixed size cache
    collect_stats "pref_sf_${i}_mc${j}_ideal" "-G 8 -M fifo -m $j --mcmethods=512"

    # Determine cost of defined assoc 
    for k in 4 8 16 32; do
      collect_stats "pref_sf_${i}_mc${j}_$k" "-G 8 -M fifo -m $j --mcmethods=$k"
    done
  done

  # Check influence of splitting the call blocks
  collect_stats "pref_sf_${i}_cbb_ideal" "-G 0 -M fifo -m 8m --mcmethods=512" "-mpatmos-split-call-blocks=true -mpatmos-preferred-subfunction-size=$i"

  for j in "4k" "2k" "1k"; do

    # Determine preferred size, determine max required assoc: use ideal assoc, fixed size cache
    collect_stats "pref_sf_${i}_cbb_mc${j}_ideal" "-G 8 -M fifo -m $j --mcmethods=512"

    # Determine cost of defined assoc 
    for k in 4 8 16 32; do
      collect_stats "pref_sf_${i}_cbb_mc${j}_$k" "-G 8 -M fifo -m $j --mcmethods=$k"
    done
  done

done

