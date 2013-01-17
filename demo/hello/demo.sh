#!/bin/bash

# current limitation: piping in commands does not work


function clean {
  rm -f hello{,.s,.ll,.o,.bc,.bc.o,.out}
}

clean
test "$1" == "clean" && exit 0


# either patmos-clang is in the path or PATMOS_INSTALL is set
if ! which patmos-clang > /dev/null; then
  PATH=${PATMOS_INSTALL:?Path to Patmos installation missing!}/bin:$PATH
fi


function info {
  echo -ne "\e[1;32m"
  echo "==============================================================================="
  echo "-> $@:"
  echo "==============================================================================="
  echo -ne "\e[0m"
}

function cmd {
  echo -ne "demo$ \e[1m$@\e[0m"
  read -s
  echo
  if [ $1 == vim ]; then
    shift
    $VILESS $@
  else
    ( $@ ) 2>&1 | tee cmd.out | ${PAGER:-cat}
  fi
}


if [ -f /usr/share/vim/vim73/macros/less.sh ]; then
    VILESS=/usr/share/vim/vim73/macros/less.sh
elif [ -d /usr/share/vim ]; then
    VILESS=$(find /usr/share/vim -name less.sh)
fi
if [ -z "$VILESS" ]; then
    VILESS="$(locate --regex '\<less.sh\>')"
fi


PAGER="less -FRSX"
#PAGER="more"

if [ "$1" == "-d" ]; then
    DRYRUN=true
fi

info "C source file"
cmd vim hello.c


info "Translate C to LLVM bitcode"
cmd patmos-clang -target patmos-unknown-unknown-elf -o hello.ll -S hello.c
cmd vim hello.ll

info "Translate C to Patmos machine code"
cmd patmos-clang -target patmos-unknown-unknown-elf -o hello.s -fpatmos-emit-asm -S hello.c
#cmd patmos-llc -march=patmos -o hello.s  hello.ll
cmd vim hello.s

info "Compile and link LLVM bitcode to an executable ELF binary"
cmd patmos-clang -v -save-temps -o hello hello.ll

info "Execute on simulator"
cmd pasim -M fifo -m 64k hello
mv cmd.out hello.out


