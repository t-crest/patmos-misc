#!/bin/bash
#
# Author: Stefan Hepp <stefan@stefant.org>
# 
# Compile and run various benchmarks and collect the pasim statistics.
# To add new setups, just add new collect_stats lines. Already existing
# results will be skipped, the script will only evaluate missing configurations.
# 
# TODO port this to ruby, integrate with the testing framework
#

###### Configuration Start #######

BENCH_SRC_DIR=../../../../patmos-benchmarks
BENCH_BUILD_DIR=build
WORK_DIR=work
PARJ=-j4

# Quick hack to make the test distributed over multiple hosts
NUM_HOSTS=1
HOST_ID=0

CLANG_ARGS="-w -mpatmos-disable-stack-cache"
CMAKE_ARGS="-DCMAKE_TOOLCHAIN_FILE=$BENCH_SRC_DIR/cmake/patmos-clang-toolchain.cmake -DENABLE_CTORTURE=false -DENABLE_EMULATOR=false -DENABLE_TESTING=true -DPLATIN_ENABLE_WCET=false -DENABLE_STACK_CACHE_ANALYSIS_TESTING=false -DENABLE_C_TESTS=false -DENABLE_MEDIABENCH=false"
PASIM_ARGS="-S dcache -d 4k -D fifo1 --mbsize 8"

###### Configuration End ########

if [ -f run.cfg ]; then
  . run.cfg
fi

# Exit on first error
set -e

function config_bench() {
  local pasim_args=$1
  local clang_args=$2

  mkdir -p $BENCH_BUILD_DIR
  (cd $BENCH_BUILD_DIR && cmake $CMAKE_ARGS -DCMAKE_C_FLAGS="$CLANG_ARGS $clang_args" -DPASIM_OPTIONS="$pasim_args" $BENCH_SRC_DIR)
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

# 
# Param testname: The Name of the configuration, used as output directory name.
# Param pasim_args: Arguments to pass to pasim
# Param clang_args: Arguments to pass to patmos-clang. 
#
# If clang_args is empty, the last non-empty clang_args passed to a previous call 
# to collect_stats will be used, and the benchmarks will only be rebuilt if the 
# previous calls were skipped.
#
# Example (assuming work/ref exists):
# collect_stats "ref" "-G 0" "--abc"  # Skipped (would rebuild benchmarks with --abc if work/ref does not exist)
# collect_stats "test1" "-G 6"        # Rebuild benchmarks with --abc since it was skipped
# collect_stats "test2" "-G 5"        # Only run pasim, reuse existing benchmarks
# 
function collect_stats() {
  local testname=$1
  local pasim_args=$2
  local clang_args=$3

  # Update the clang args that should be used for this benchmark
  if [ ! -z "$clang_args" ]; then
    current_clang_args="$clang_args"
  fi

  # Round robin distribution of jobs over multiple hosts
  if [ ! -z "$clang_args" ]; then
    let host_cnt=$host_cnt+1
  fi
  if [ $host_cnt == $NUM_HOSTS ]; then
    host_cnt=0
  fi

  if [ $host_cnt != $HOST_ID ]; then
    echo 
    echo "**** Skipping configuration $testname: executed by host $host_cnt *****"
    echo
  elif [ ! -d $WORK_DIR/$testname ]; then
    echo
    echo "**** Running configuration $testname ****"
    echo

    config_bench "$pasim_args" "$current_clang_args"

    if [ "$current_clang_args" != "$last_clang_args" ]; then
      echo
      echo "# Building with options $CLANG_ARGS $current_clang_args"
      echo 
      build_bench
      last_clang_args="$current_clang_args"
    fi

    run_bench $testname
  else
    echo
    echo "**** Skipping configuration $testname: already exists ****"
    echo
  fi
}



# Ideal cache, no splitting; determine max. code size, reference for other runs
collect_stats "ideal" "-G 0 -M fifo -m 8m --mcmethods=512" "-mpatmos-disable-function-splitter"

# I-cache without splitting, for comparison
for j in "8m" "16k" "8k" "4k" "2k" "1k"; do
  collect_stats "nosplit_ic${j}_lru2" "-G 7 -C icache -K lru2 -m $j"
  collect_stats "nosplit_ic${j}_lru4" "-G 7 -C icache -K lru4 -m $j"
done


# Check influence of max-SF-size: ideal cache, fixed overhead for regions, split BBs
for i in 8192 4096 2048 1024 512 256; do
  collect_stats "max_sf_$i" "-G 0 -M fifo -m 8m --mcmethods=512" "-mpatmos-method-cache-size=$i -mpatmos-split-call-blocks=false -mpatmos-preferred-subfunction-size=256"
done

# Check influence of function splitter
for i in 256 1024 512 384 192 32 96 320 64 448; do
  collect_stats "pref_sf_${i}_ideal" "-G 0 -M fifo -m 8m --mcmethods=512" "-mpatmos-split-call-blocks=false -mpatmos-preferred-subfunction-size=$i"

  # Size of cache in kb
  for j in "32" "16" "8" "4" "2" "1"; do

    # Determine preferred size, determine max required assoc: use ideal assoc, fixed size cache
    collect_stats "pref_sf_${i}_mc${j}k_ideal"    "-G 7 -M fifo -m ${j}k --mcmethods=512"
    collect_stats "pref_sf_${i}_mc${j}k_ideal_vb" "-G 7 -M fifo -m ${j}k --mcmethods=512 --psize=1k"

    # Determine cost of predefined assoc
    for k in 4 8 16 32 64; do
      blocksize=`echo "$j*1024/$k" | bc`

      # Compare variable-size, fixed-block, LRU and variable burst, TDM multicore
      collect_stats "pref_sf_${i}_mc${j}k_${k}"     "-G 7 -M fifo -m ${j}k --mcmethods=$k"
      collect_stats "pref_sf_${i}_mc${j}k_${k}_fb"  "-G 7 -M fifo -m ${j}k --mcmethods=0 --mbsize=$blocksize"
      collect_stats "pref_sf_${i}_mc${j}k_${k}_lru" "-G 7 -M lru  -m ${j}k --mcmethods=0 --mbsize=$blocksize"

      collect_stats "pref_sf_${i}_mc${j}k_${k}_vb"  "-G 7 -M fifo -m ${j}k --mcmethods=$k --psize=1k"
      collect_stats "pref_sf_${i}_mc${j}k_${k}_tdm" "-G 7 -M fifo -m ${j}k --mcmethods=$k -N 4 --tdelay=8"
    done

    # compare with I-cache
    collect_stats "pref_sf_${i}_ic${j}k_lru2"     "-G 7 -C icache -K lru2 -m ${j}k"
    collect_stats "pref_sf_${i}_ic${j}k_lru4"     "-G 7 -C icache -K lru4 -m ${j}k"
    collect_stats "pref_sf_${i}_ic${j}k_lru2_tdm" "-G 7 -C icache -K lru2 -m ${j}k -N 4 --tdelay=8"
    collect_stats "pref_sf_${i}_ic${j}k_lru4_tdm" "-G 7 -C icache -K lru4 -m ${j}k -N 4 --tdelay=8"
  done

  # Check influence of splitting the call blocks
  collect_stats "pref_sf_${i}_cbb_ideal" "-G 0 -M fifo -m 8m --mcmethods=512" "-mpatmos-split-call-blocks=true -mpatmos-preferred-subfunction-size=$i"

  # size of cache in kb
  for j in "8" "4" "2" "1"; do

    # Determine preferred size, determine max required assoc: use ideal assoc, fixed size cache
    collect_stats "pref_sf_${i}_cbb_mc${j}k_ideal" "-G 7 -M fifo -m ${j}k --mcmethods=512"

    # Determine cost of predefined assoc 
    for k in 4 8 16 32 64; do
      blocksize=`echo "$j*1024/$k" | bc`

      collect_stats "pref_sf_${i}_cbb_mc${j}k_$k"       "-G 7 -M fifo -m ${j}k --mcmethods=$k"
      collect_stats "pref_sf_${i}_cbb_mc${j}k_${k}_fb"  "-G 7 -M fifo -m ${j}k --mcmethods=0 --mbsize=$blocksize"
      collect_stats "pref_sf_${i}_cbb_mc${j}k_${k}_lru" "-G 7 -M lru  -m ${j}k --mcmethods=0 --mbsize=$blocksize"

      collect_stats "pref_sf_${i}_cbb_mc${j}k_${k}_vb"  "-G 7 -M fifo -m ${j}k --mcmethods=$k --psize=1k"
      collect_stats "pref_sf_${i}_cbb_mc${j}k_${k}_tdm" "-G 7 -M fifo -m ${j}k --mcmethods=$k -N 4 --tdelay=8"
    done
    
  done

done

