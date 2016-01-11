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

# Disable features not yet correctly supported by the analysis (?)
#CLANG_ARGS="-w -Xllc -mpatmos-cfl=delayed -mpatmos-disable-stack-cache"
CLANG_ARGS="-w"

PLATIN_CONFIG_OPTS="--target patmos-unknown-unknown-elf -g 64m --update-heap-syms 64k,32"
PLATIN_OPTIONS="--wca-use-gurobi --accept-corrected-rgs"

CMAKE_ARGS="-DCMAKE_TOOLCHAIN_FILE=$BENCH_SRC_DIR/cmake/patmos-clang-toolchain.cmake -DENABLE_CTORTURE=false -DENABLE_EMULATOR=false -DENABLE_TESTING=true -DPLATIN_ENABLE_WCET=true -DENABLE_STACK_CACHE_ANALYSIS_TESTING=false -DENABLE_C_TESTS=false -DENABLE_WTC14=false -DENABLE_TCAS=false -DENABLE_MEDIABENCH=false -DPLATIN_ENABLE_AIT=false -DTACLE_BENCH=true -DENABLE_HELI=false -DENABLE_NONFREE=false -DENABLE_DEBIE=false"

TM_DEFAULT="-G 21"
TM_PAGED=""
TM_TDM4=""
TM_TDM64=""

MCACHE_IDEAL="-M fifo -m 8m"

MCACHE_NOBLOCK="--set-cache-attr method-cache,fill-mode,noblock"

MAX_FUNCTION_SIZE=1024

###### Configuration End ########

if [ -f run.cfg ]; then
  . run.cfg
fi

# Exit on first error
set -e

function config_bench() {
  local config_pml=$1
  local clang_args=$2
  local pasim_args=$3

  (cd $BENCH_BUILD_DIR && cmake $CMAKE_ARGS -DCMAKE_C_FLAGS="$CLANG_ARGS $clang_args" -DPASIM_EXTRA_OPTIONS="$pasim_args" -DCONFIG_PML="$config_pml" -DCONFIG_PML_LARGERAM="$config_pml" -DPLATIN_OPTIONS="$PLATIN_OPTIONS" $BENCH_SRC_DIR)
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

  # collect wcet files
  find $BENCH_BUILD_DIR -iname "*-wcet.txt" -exec cp -f {} $WORK_DIR/$testname \;
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
  local config_args=$2
  local clang_args=$3

  # Update the clang args that should be used for this benchmark
  if [ ! -z "$clang_args" ]; then
    current_clang_args="$clang_args"
  fi

  mkdir -p $BENCH_BUILD_DIR/configs

  # Create an architecture PML file
  config_pml=`readlink -f "$BENCH_BUILD_DIR/configs/config_${testname}.pml"`
  platin pml-config $PLATIN_CONFIG_OPTS $config_args -o $config_pml

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

    config_bench "$config_pml" "$current_clang_args"

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

function eval_caches() {
  local i=$1
  local scc=$2

  if [[ $scc-8 -gt $MAX_FUNCTION_SIZE ]]; then
    return
  fi

  fsplit_options="-mpatmos-max-subfunction-size=$MAX_FUNCTION_SIZE -mpatmos-preferred-subfunction-size=$i -mpatmos-preferred-scc-size=$scc"

  collect_stats "pref_sf_${i}_scc_${scc}_ideal" "mc_ideal" "-Xllc -mpatmos-split-call-blocks=false $fsplit_options"

  # Size of cache in kb
  for j in "32" "16" "8" "4" "2" "1"; do
    
    if [[ $j*1024 -lt $MAX_FUNCTION_SIZE ]]; then
      break
    fi

    # Determine preferred size, determine max required assoc: use ideal assoc, fixed size cache
    #collect_stats "pref_sf_${i}_scc_${scc}_mc${j}k_ideal"    "mc${j}k_ideal"
    #collect_stats "pref_sf_${i}_scc_${scc}_mc${j}k_ideal_vb" "mc${j}k_ideal_vb"

    # Determine cost of predefined assoc
    for k in 8 16 32 64; do
      blocksize=`echo "$j*1024/$k" | bc`

      # Compare variable-size, fixed-block, LRU and variable burst, TDM multicore
      collect_stats "pref_sf_${i}_scc_${scc}_mc${j}k_${k}"     "mc${j}k_${k}"
      #collect_stats "pref_sf_${i}_scc_${scc}_mc${j}k_${k}_fb"  "-G 7 -M fifo -m ${j}k --mcmethods=0 --mbsize=$blocksize"
      #collect_stats "pref_sf_${i}_scc_${scc}_mc${j}k_${k}_lru" "-G 7 -M lru  -m ${j}k --mcmethods=0 --mbsize=$blocksize"

      collect_stats "pref_sf_${i}_scc_${scc}_mc${j}k_${k}_vb"  "mc${j}k_${k}_vb"
      #collect_stats "pref_sf_${i}_scc_${scc}_mc${j}k_${k}_tdm" "-G 7 -M fifo -m ${j}k --mcmethods=$k -N 4 --tdelay=8"
    done

  done

  # Check influence of splitting the call blocks
  #collect_stats "pref_sf_${i}_scc_${scc}_cbb_ideal" "$MCACHE_IDEAL" "-Xllc -mpatmos-split-call-blocks=true $fsplit_options"

  # size of cache in kb
  for j in "32" "16" "8" "4" "2" "1"; do

    if [[ $j*1024 -gt $MAX_FUNCTION_SIZE ]]; then
      break
    fi

    # Determine preferred size, determine max required assoc: use ideal assoc, fixed size cache
    #collect_stats "pref_sf_${i}_scc_${scc}_cbb_mc${j}k_ideal" "-M fifo -m ${j}k --mcmethods=512"

    # Determine cost of predefined assoc 
    for k in 8 16 32 64 128; do
      blocksize=`echo "$j*1024/$k" | bc`

      #collect_stats "pref_sf_${i}_scc_${scc}_cbb_mc${j}k_$k"       "-M fifo -m ${j}k --mcmethods=$k"
      #collect_stats "pref_sf_${i}_scc_${scc}_cbb_mc${j}k_${k}_fb"  "-G 7 -M fifo -m ${j}k --mcmethods=0 --mbsize=$blocksize"
      #collect_stats "pref_sf_${i}_scc_${scc}_cbb_mc${j}k_${k}_lru" "-G 7 -M lru  -m ${j}k --mcmethods=0 --mbsize=$blocksize"

      #collect_stats "pref_sf_${i}_scc_${scc}_cbb_mc${j}k_${k}_vb"  "-M fifo -m ${j}k --mcmethods=$k --psize=1k"
      #collect_stats "pref_sf_${i}_scc_${scc}_cbb_mc${j}k_${k}_tdm" "-G 7 -M fifo -m ${j}k --mcmethods=$k -N 4 --tdelay=8"
    done
    
    # Not evaluating I$ here, compare with non-cbb versions
  done
}

## LLC Options
# -mpatmos-split-call-blocks = false
# -mpatmos-split-calls = none, all, grow, analyze
# -mpatmos-split-functions-with-call-in-loop = true
#
# -mpatmos-split-disposable = true
# -mpatmos-dispose-blocks = none, all, scc, analyze
#
# -mpatmos-use-crit-edge-weight = false
# 
# -mpatmos-preferred-scc-size
# -mpatmos-preferred-subfunction-size
# -mpatmos-max-subfunction-size

# Ideal cache, no splitting; determine max. code size, reference for other runs
collect_stats "nosplit_ideal" "$MCACHE_IDEAL" "-Xllc -mpatmos-disable-function-splitter"

# I-cache without splitting, for comparison
for j in "16" "8" "4" "2" "1"; do
  echo
  # Emptyclang options: function splitter is disabled by platin tool-config for LRU caches
  collect_stats "nosplit_ic${j}k_dm"   "-C icache -M dm -m ${j}k"
  collect_stats "nosplit_ic${j}k_lru2" "-C icache -M lru2 -m ${j}k"
  collect_stats "nosplit_ic${j}k_lru4" "-C icache -M lru4 -m ${j}k"
  collect_stats "nosplit_ic${j}k_lru8" "-C icache -M lru8 -m ${j}k"
  collect_stats "nosplit_ic${j}k_lru" "-C icache -M lru -m ${j}k"
  collect_stats "nosplit_ic${j}k_fifo2" "-C icache -M fifo2 -m ${j}k"
  collect_stats "nosplit_ic${j}k_fifo4" "-C icache -M fifo4 -m ${j}k"
  collect_stats "nosplit_ic${j}k_fifo8" "-C icache -M fifo8 -m ${j}k"
  collect_stats "nosplit_ic${j}k_fifo" "-C icache -M fifo -m ${j}k"
done

# Check influence of max-SF-size: ideal cache, fixed overhead for regions, split BBs
for sf in 2048 1024 512 256; do
  collect_stats "max_sf${sf}_ideal" "$MCACHE_IDEAL" "-mpatmos-max-subfunction-size=$sf -mpatmos-preferred-subfunction-size=256"
  for i in 16 8 4 2 1; do
    for j in 8 16 32 64; do
      collect_stats "max_sf${sf}_mc${i}k_fifo${j}" "-M fifo$j -m${i}k"
    done
  done
done

# Evaluate nonblocking burst mode
# TODO use --wca-mcache-power-dfa
for k in 268 128 512 768 1024; do
  for rqs in 16 0 32 64; do
    collect_stats "noblock_sf${k}_rqs${rqs}_ideal" "$MCACHE_IDEAL $MCACHE_NOBLOCK --set-cache-attr method-cache,request-size,$rqs" "-mpatmos-max-subfunction-size=1024 -mpatmos-preferred-subfunction-size=$k"
    for i in 16 8 4 2 1; do
      for j in 8 16 32 64; do
        collect_stats "noblock_sf${k}_rqs${rqs}_mc${i}k_fifo${j}" "-M fifo$j -m${i}k $MCACHE_NOBLOCK --set-cache-attr method-cache,request-size,$rqs"
      done
    done
  done
done



# Check influence of function splitter
#for i in 32 64 128 256 512 1024 96 192 384 320 448; do
#  eval_caches $i $i
#  eval_caches $i 1024
#  eval_caches $i 2048
#done

