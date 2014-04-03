#
# Makefile for bsearch demo
#

SHELL=/bin/bash

BS ?= bsearch_dep

.PHONY: all clean

all: $(BS).elf $(BS).sp.elf $(BS).host $(BS).trace $(BS).sp.trace


test.c: bsearch.h
	touch $@

$(BS).host: test.c $(BS).c
	gcc -g -DBS=$(BS) -o $@ $^
	./$@

$(BS).elf: test.c $(BS).c
	patmos-clang -DBS=$(BS) -o $@ $^

$(BS).sp.elf: test.c $(BS).c
	patmos-clang -DBS=$(BS) -mpatmos-singlepath=$(BS) \
	  -Xllc -debug-only=patmos-singlepath -save-temps -o $@ $^ 2> $(BS).log
	@# obtain CFG:
	patmos-opt -analyze -dot-cfg-only $@.opt.bc > /dev/null 2>&1
	dot -Tpng -o $(BS).png cfg.$(BS).dot
	rm *.dot *.i *.o *.bc


%.trace: %.elf
	pasim --debug=0 --debug-fmt=blocks --debug-file=>(grep '$(BS)' > $@) \
	  -V $< > $*.out
	@sed -ne '1,/^Cyc :/ p' $*.out | head -n -1
	@echo "#calls        #min        #max          #avg"
	@grep -A2 '<$(BS)>' $*.out

%.dis: %.elf
	patmos-llvm-objdump -d -fpatmos-print-bytes=call $< > $@

clean:
	rm -fr *.elf *.host *.i *.o *.bc *.trace *.dis *.log *.out *.png
