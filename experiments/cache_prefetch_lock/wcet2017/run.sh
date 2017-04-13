#!/bin/bash

function report {
  local bl=$1
  make clean
  time make XML_BURSTLENGTH=${bl} 2>&1 | tee make.log
  tar czf report-8k-bl${bl}.tgz \
    *.rpt *.elf *.txt *.sym ?cache.xml patmos_emu* make.log
}

