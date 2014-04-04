#
# Makefile for bsearch demo
#

SHELL=/bin/bash


ALL = bsearch_dep bsearch_ilb bsearch_ilc


.PHONY: all clean

target_suffixes := host elf sp.elf trace sp.trace dis sp.dis
targets = $(addprefix $(targ)., $(target_suffixes))

all: $(foreach targ, $(ALL), $(targets))

test.c: bsearch.h
	touch $@

%.host: %.c test.c
	gcc -g -DBS=$* -o $@ $^
	./$@

%.elf: %.c test.c
	patmos-clang -DBS=$* -o $@ $^

%.sp.elf: %.c test.c
	patmos-clang -DBS=$* -mpatmos-singlepath=$* \
	  -Xllc -debug-only=patmos-singlepath -save-temps -o $@ $^ 2> $*.log
	@# obtain CFG:
	patmos-opt -analyze -dot-cfg-only $@.opt.bc > /dev/null 2>&1
	dot -Tpng -o $*.png cfg.$*.dot
	rm *.dot *.i *.o *.bc


# target-specific variable BS
bsearch_dep.trace bsearch_dep.sp.trace : BS = bsearch_dep
bsearch_ilb.trace bsearch_ilb.sp.trace : BS = bsearch_ilb
bsearch_ilc.trace bsearch_ilc.sp.trace : BS = bsearch_ilc

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
