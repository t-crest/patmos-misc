#!/bin/bash

ELF=${1?"No binary specified"}

patmos-llvm-objdump -t ${ELF} | grep -E "^[0-9a-f]{8} [gl]\s+F\s+.text" | \
  awk '{print $1, $6}' | sort
