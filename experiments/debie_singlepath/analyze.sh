#!/bin/bash

if [ "$1" != "wcet" -a "$1" != "pasim" -a "$1" != "print" ] || [ "$2" == "" ]; then
  echo "Usage: $0 wcet|pasim|print <binary> [<configname>]"
  echo
  echo "If a configname (like 'nodc' or 'ideal') is given, 'print' will use"
  echo "the results of the corresponding result dir."
  echo 
  exit 1
fi

MODE=$1
BINFILE=$2
#BINFILE=debie1.sp

if [ ! -f $BINFILE ]; then
  echo "Error: binary $BINFILE does not exist"
  exit 2
fi

ARCHPML=config_default.pml

if [ "$3" != "" ]; then
  ARCHPML="config_${3}.pml"
fi

#SPROOTS="TC_InterruptService,TM_InterruptService,HandleHitTrigger,HandleTelecommand,HandleAcquisition,HandleHealthMonitoring"
SPROOTS="TC_InterruptService TM_InterruptService HandleHitTrigger HandleTelecommand HandleAcquisition"

function run_pasim() {
  binfile=$1

  pasim_opt=`platin tool-config -i $ARCHPML -t pasim`

  for root in $SPROOTS; do

    echo
    echo "**** Running pasim on $binfile for $root ****"
    echo

    pasim $pasim_opt -V $binfile --flush-caches $root 2>pasim.${binfile}.${root}.log

  done
}

function print_pasim() {
  binfile=$1
  resultdir=$2
  if [ -z $resultdir ]; then
    resultdir="."
  fi

  echo
  echo "**** Simulation Results for $binfile using $ARCHPML ****"
  echo

  echo -e "  Function         \tmin\tmax"
  echo "  --------------------------------------------"

  for root in $SPROOTS; do

    line=`grep -A 2 "$root" $resultdir/pasim.${binfile}.${root}.log | tail -n 1`

    min=`echo $line | awk '{print $2}'`
    max=`echo $line | awk '{print $3}'`

    echo -e "  $root\t$min\t$max"

  done
}

function run_wcet() {
  binfile=$1

  reportfile="wcet.${binfile}.pml"

  mkdir -p tmp
  rm -f $reportfile

  for root in $SPROOTS; do

    echo
    echo "**** Running platin wcet on $binfile for $root ****"
    echo

    platin wcet -i ${binfile}.pml -i ${ARCHPML} -b ${binfile} -e $root --outdir tmp --report $reportfile --append-report --enable-wca
  done
}

function print_wcet() {
  binfile=$1
  resultdir=$2
  if [ -z $resultdir ]; then
    resultdir="."
  fi

  echo
  echo "**** WCET Results for $binfile using $ARCHPML ****"
  echo

  reportfile="$resultdir/wcet.${binfile}.pml"

  if [ ! -f $reportfile ]; then
    echo "Report file not found!"
    echo
    return
  fi

  echo -e "  Function         \t\tWCET (aiT)\tWCET (platin)"
  echo "  ------------------------------------------------------------"

  for root in $SPROOTS; do
    cycles_wca=`grep -A 4 "$root" $reportfile | grep -A 3 "platin" | grep "cycles:" | sed "s/.*: \([-0-9]*\).*/\1/"`
    cycles_ait=`grep -A 4 "$root" $reportfile | grep -A 3 "aiT"    | grep "cycles:" | sed "s/.*: \([-0-9]*\).*/\1/"`
    
    echo -e "  $root\t\t$cycles_ait\t\t$cycles_wca"
  done
  
}

if [ "$MODE" == "pasim" ]; then
  run_pasim $BINFILE
  print_pasim $BINFILE
fi

if [ "$MODE" == "wcet" ]; then
  run_wcet $BINFILE
  print_wcet $BINFILE
fi

if [ "$MODE" == "print" ]; then
  if [ "$3" != "" ]; then
    resultdir="results/$3"
  fi

  print_pasim $BINFILE $resultdir
  print_wcet $BINFILE $resultdir
fi
