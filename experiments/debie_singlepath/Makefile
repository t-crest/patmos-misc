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

# for debugging: -mpatmos-disable-function-splitter -mpatmos-disable-vliw -mpatmos-disable-post-ra -Xllc --debug-only=patmos-singlepath
CFLAGS = -fno-builtin -w -g -O2 -fno-unroll-loops \
-Xllc --debug-only=patmos-singlepath -mpatmos-disable-vliw -Xllc -mpatmos-cfl=non-delayed -mpatmos-disable-post-ra -mpatmos-disable-function-splitter -Xllc -mpatmos-basicblock-align=8

# additional flags for sp codegen
CFLAGS_SP = -Xopt -disable-early-taildup \
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
	$(CC) $(CFLAGS) $(CFLAGS_ARCH) $(CFLAGS_CONV) -o $@ $(OBJS) 2>&1 | tee debie.log

# The debie singlepath binary
debie1.sp.elf:
	cd $(BUILDDIR) && $(MAKE) $(DEBIEOBJS)
	$(CC) $(CFLAGS) $(CFLAGS_ARCH) $(CFLAGS_SP) \
	  -mpatmos-singlepath=$(subst $(space),$(comma),$(SPROOTS)) \
	  -o $@ $(OBJS)  2>&1 | tee debie.sp.log | ./cpdot.sh debie

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

%.times: %.elf
	rm -f $@
	$(PASIM) --debug=0 --debug-fmt=calls-indent --debug-file=$@.tmp $<
	for root in $(SPROOTS); do \
	  ./profile.sh $${root} <$@.tmp >> $@; \
	  done
	rm -f $@.tmp

# create debug log / stats when converting only a particular function
debie1.%.log:
	$(CC) $(CFLAGS) $(CFLAGS_ARCH) $(CFLAGS_SP) \
	  -mpatmos-singlepath=$* \
	  -Xllc --debug-only=patmos-singlepath -Xllc -stats \
	  -o debie1.tmp.elf $(OBJS) 2> $@
	rm -f debie1.tmp.elf

debie1.stats: debie1.sp.elf debie1.elf $(foreach root,$(SPROOTS),debie1.$(root).log)
	echo "Task Conv SP" > $@
	for root in $(SPROOTS); do \
	  echo -n "$${root}" >> $@ ; \
	  ./stats.sh debie1.$${root}.log debie1.elf    | awk '/Total:/ {printf " %d", $$2}' >> $@ ; \
	  ./stats.sh debie1.$${root}.log debie1.sp.elf | awk '/Total:/ {printf " %d", $$2}' >> $@ ; \
	  echo >> $@ ; \
	  done;

clean:
	rm -f *.dis *.elf *.sim *.bc *.elf.pml *.wcet.pml *.times *.log *.stats
	rm -fr ./tmp/
