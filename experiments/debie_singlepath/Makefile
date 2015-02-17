#
# Makefile for debie1 singlepath evaluation
#
# Authors:
# 	Daniel Prokesch <daniel@vmars.tuwien.ac.at>
# 	Stefan Hepp <hepp@complang.tuwien.ac.at>
#

SHELL=/bin/bash


BUILDDIR := ../../../bench/build
#BUILDDIR := ../../../patmos-benchmarks-obj/

DEBIEBCDIR := Debie1-e/code

BCFILES := class.c.bc classtab.c.bc debie.c.bc health.c.bc hw_if.c.bc measure.c.bc tc_hand.c.bc telem.c.bc harness/harness.c.bc

DEBIEOBJS = $(addprefix $(DEBIEBCDIR)/CMakeFiles/debie1.dir/,$(BCFILES)) $(DEBIEBCDIR)/patmos/clang/libdebie1-target.a
OBJS = $(addprefix $(BUILDDIR)/,$(DEBIEOBJS))

CC = patmos-clang

# for debugging: -mpatmos-disable-function-splitter -mpatmos-disable-vliw -mpatmos-disable-post-ra
CFLAGS = -fno-builtin -w -g -O2 -fno-unroll-loops

# additional flags for sp codegen
CFLAGS_SP = -mpatmos-singlepath=$(subst $(space),$(comma),$(SPROOTS)) \
	    -Xopt -disable-early-taildup \
	    -Xopt -disable-tail-duplicate \
	    -Xopt -enable-tail-merge \
	    -Xllc -disable-early-taildup \
	    -Xllc -disable-tail-duplicate \
	    -Xllc -enable-tail-merge

CFLAGS_CONV = -mpreemit-bitcode=$@.bc -mserialize=$@.pml \
	      -mserialize-roots=$(subst $(space),$(comma),$(SPROOTS)) \
	      -mpatmos-sca-serialize=$@.scml



ARCHPML ?= config_ideal.pml
CFLAGS_ARCH = $(shell platin tool-config -i $(ARCHPML) -t clang)

PASIM = pasim $(shell platin tool-config -i $(ARCHPML) -t pasim) \
		--flush-caches=Trampoline_CacheFlush


SPROOTS = $(shell head -n1 "sproots.txt")

null  :=
space := $(null) #
comma := ,

# Filename of the global report
REPORT := report.txt

.PRECIOUS:

.PHONY: all clean

# As top level target, create a report
all:
	echo "Use ./report.sh to start the evaluation."

# The debie conventional binary
debie1.elf:
	cd $(BUILDDIR) && $(MAKE) $(DEBIEOBJS)
	$(CC) $(CFLAGS) $(CFLAGS_ARCH) $(CFLAGS_CONV) -o $@ $(OBJS)

# The debie singlepath binary
debie1.sp.elf:
	cd $(BUILDDIR) && $(MAKE) $(DEBIEOBJS)
	$(CC) $(CFLAGS) $(CFLAGS_ARCH) $(CFLAGS_SP) -o $@ $(OBJS)

%.dis: %.elf
	patmos-llvm-objdump -d $< > $@




%.sim: %.elf
	$(PASIM) -V $< |& grep -A2 -E '<($(subst $(space),|,$(SPROOTS)))>' \
	  > $@

%.wcet.pml: %.elf
	mkdir -p tmp
	for root in $(SPROOTS); do \
	  platin wcet -i $<.pml -i $(ARCHPML) -b $< -e $$root --outdir tmp \
	  --report $@ --append-report --enable-wca; \
	  done

%.symbols: %.elf
	patmos-llvm-objdump -t $< | \
	  grep -E '$(subst $(space),|,$(SPROOTS))' | \
	  awk 'BEGIN {OFS="\t"} { print $$1, strtonum("0x"$$5), $$6 }' | \
	  tee $@

%.times: %.elf
	rm -f $@
	$(PASIM) --debug=0 --debug-fmt=calls-indent --debug-file=$@.tmp $<
	for root in $(SPROOTS); do \
	  ./profile.sh $${root} <$@.tmp >> $@; \
	  done
	rm -f $@.tmp





clean:
	rm -f *.dis *.elf *.sim *.bc *.elf.pml *.wcet.pml *.times *.symbols
	rm -fr ./tmp/
