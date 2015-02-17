#!/bin/bash

# TODO read this from build.cfg..
#BUILDDIR=../../../patmos-benchmarks-obj/
BUILDDIR=../../../bench/build/

ARCHPML=config_default.pml

BCDIR=$BUILDDIR/Debie1-e/code


#SPROOTS="TC_InterruptService,TM_InterruptService,HandleHitTrigger,HandleTelecommand,HandleAcquisition,HandleHealthMonitoring"
SPROOTS="TC_InterruptService,TM_InterruptService,HandleHitTrigger,HandleTelecommand,HandleAcquisition"

function compile() {
  OUTFILE=$1
  shift

  CC="patmos-clang -fno-builtin -w -g $BCDIR/CMakeFiles/debie1.dir/class.c.bc $BCDIR/CMakeFiles/debie1.dir/classtab.c.bc $BCDIR/CMakeFiles/debie1.dir/debie.c.bc \
                                      $BCDIR/CMakeFiles/debie1.dir/health.c.bc $BCDIR/CMakeFiles/debie1.dir/hw_if.c.bc $BCDIR/CMakeFiles/debie1.dir/measure.c.bc \
				      $BCDIR/CMakeFiles/debie1.dir/tc_hand.c.bc $BCDIR/CMakeFiles/debie1.dir/telem.c.bc $BCDIR/CMakeFiles/debie1.dir/harness/harness.c.bc \
		   -mpreemit-bitcode=${OUTFILE}.bc -mserialize=${OUTFILE}.pml -mpatmos-sca-serialize=${OUTFILE}.scml $BCDIR/patmos/clang/libdebie1-target.a -O2"
# -mpatmos-disable-vliw -mpatmos-disable-function-splitter -mpatmos-disable-post-ra

  echo "Compiling $OUTFILE"
  $CC `platin tool-config -i $ARCHPML -t clang` -o ${OUTFILE} -Xllc -mserialize-roots=${SPROOTS} "$@"
}


compile debie1
compile debie1.sp -mpatmos-singlepath=${SPROOTS}


#patmos-llvm-objdump -d debie1.sp > debie1.sp.dis
#$CC -o debie1.sp -mpatmos-singlepath=${SPROOTS} -Xllc --debug-only=patmos-singlepath 2>&1 | tee debie1.log | ./cpdot.sh debie
#for f in *.dot; do dot -Tpng $f > ${f%.dot}.png; done
