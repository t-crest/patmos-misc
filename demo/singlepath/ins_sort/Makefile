#
# Makefile for insort demo
#

SHELL=/bin/bash


ALL = insort_dep insort_ilb insort_ilc


.PHONY: all clean

target_suffixes := host elf sp.elf trace sp.trace dis sp.dis
targets = $(addprefix $(targ)., $(target_suffixes))

all: $(foreach targ, $(ALL), $(targets))

test.c: insort.h genperm.h
	touch $@

%.host: %.c test.c genperm.c
	gcc -g -DIS=$* -o $@ $^
	./$@

%.elf: %.c test.c genperm.c
	patmos-clang -mpatmos-disable-ifcvt -DIS=$* -o $@ $^

%.sp.elf: %.c test.c genperm.c
	patmos-clang -DIS=$* -mpatmos-singlepath=$* \
	  -Xllc -debug-only=patmos-singlepath -Xllc -stats -save-temps \
	  -o $@ $^ 2> $*.log
	@# obtain CFG:
	patmos-opt -analyze -dot-cfg-only $@.opt.bc > /dev/null 2>&1
	dot -Tpng -o $*.png cfg.$*.dot
	rm *.dot *.i *.o *.bc


# target-specific variable IS
insort_dep.trace insort_dep.sp.trace : IS = insort_dep
insort_ilb.trace insort_ilb.sp.trace : IS = insort_ilb
insort_ilc.trace insort_ilc.sp.trace : IS = insort_ilc

%.trace: %.elf
	pasim --debug=0 --debug-fmt=blocks --debug-file=>(grep '$(IS)' > $@) \
	  -V --mckind=ideal $< > $*.out
	@sed -ne '1,/^Cyc :/ p' $*.out | head -n -1
	@echo "#calls        #min        #max          #avg"
	@grep -A2 '<$(IS)>' $*.out

%.dis: %.elf
	patmos-llvm-objdump -d -fpatmos-print-bytes=call $< > $@

clean:
	rm -fr *.elf *.host *.i *.o *.bc *.trace *.dis *.log *.out *.png
