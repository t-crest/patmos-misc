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
CLANG_ARGS="-w"

PLATIN_OPTIONS="--tolerated-underestimation 100 --combine-wca"

CMAKE_ARGS="-DCMAKE_TOOLCHAIN_FILE=$BENCH_SRC_DIR/cmake/patmos-clang-toolchain.cmake -DENABLE_CTORTURE=false -DENABLE_EMULATOR=false -DENABLE_TESTING=true -DPLATIN_ENABLE_WCET=true -DENABLE_STACK_CACHE_ANALYSIS_TESTING=false -DENABLE_C_TESTS=false -DENABLE_MEDIABENCH=false -DENABLE_MIBENCH=false -DENABLE_DEBIE=false -DPLATIN_ENABLE_AIT=true"

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

  mkdir -p $BENCH_BUILD_DIR
  (cd $BENCH_BUILD_DIR && cmake $CMAKE_ARGS -DCMAKE_C_FLAGS="$CLANG_ARGS $clang_args" -DPASIM_EXTRA_OPTIONS="$pasim_args" -DCONFIG_PML="$config_pml" -DCONFIG_PML_HW="$config_pml" -DPLATIN_OPTIONS="$PLATIN_OPTIONS" $BENCH_SRC_DIR)
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
  local configname=$2
  local clang_args=$3

  # Update the clang args that should be used for this benchmark
  if [ ! -z "$clang_args" ]; then
    current_clang_args="$clang_args"
  fi

  # Check for an architecture PML file
  config_pml=`readlink -f "configs/config_${configname}.pml"`
  if [ ! -f $config_pml ]; then
    echo
    echo "**** Skipping configuration $testname: no config PML file '${configname}' found! *****"
    echo
    return
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

# Compare different -O levels
collect_stats "default_O2" "default" "-O2"
# TODO fixme (compress, duff, lms)
collect_stats "default_O0" "default" "-O0"
# TODO fixme (compress, duff, lms, ns, matmult, ndes, adpcm, lcdnum, ..)
collect_stats "default_O1" "default" "-O1"
collect_stats "default_O3" "default" "-O3"
collect_stats "default_none" "default" "-O0 -mpatmos-disable-stack-cache -mpatmos-disable-vliw -Xllc -mpatmos-cfl=delayed"
# no-link-opts
collect_stats "default_nolinkopts" "default" "-fpatmos-skip-opt"

# Compare split-cache (-O2) vs. splitcache + bypass, no stackcache
collect_stats "default_nostackcache" "default" "-mpatmos-disable-stack-cache"
collect_stats "dc4k_nostackcache"    "dc4k"    "-mpatmos-disable-stack-cache"

# Compare dual-issue (-O2) vs. single-issue
collect_stats "default_singleissue" "default" "-mpatmos-disable-vliw"
#collect_stats "default_singleissue_nopostra" "default" "-mpatmos-disable-vliw -mpatmos-disable-post-ra"
#collect_stats "default_nopostra"    "default" "-mpatmos-disable-post-ra"


# Compare mixed-delayed branches (-O2) vs. non-delayed / delayed
collect_stats "default_delayed"    "default" "-Xllc -mpatmos-cfl=delayed"
collect_stats "default_nondelayed" "default" "-Xllc -mpatmos-cfl=non-delayed"


# Compare all optimizations vs. no if-convert, no loop transforms, ..
collect_stats "default_noifcvt"    "default" "-mpatmos-disable-ifcvt"


