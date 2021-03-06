#
# Makefile in the singlepath evaluation bench.
#
# Author: Daniel Prokesch
#

# We use bash as shell for the makefile.
SHELL=/bin/bash

comma := ,

V ?= 0
ifneq ($V, 0)
  VERBOSE=-v -save-temps
else
  VERBOSE=
endif


#PASIMDBG ?= --debug=0 --debug-fmt=blocks --debug-file=$@

CFLAGS = -fno-unroll-loops \
	 -DTEST_PRINT_RESULTS

CFLAGSSP = $(CFLAGS) \
	   -Xopt -disable-early-taildup \
	   -Xopt -disable-tail-duplicate \
	   -Xopt -enable-tail-merge \
	   -Xllc -disable-early-taildup \
	   -Xllc -disable-tail-duplicate \
	   -Xllc -enable-tail-merge

PMLCONFIG ?= config/config_ideal.pml

CONFIG_CLANG = $(shell platin tool-config -i $(PMLCONFIG) -t clang)
CONFIG_PASIM = $(shell platin tool-config -i $(PMLCONFIG) -t pasim)


SPROOTS = $(shell grep ^$(*:.sp=)= sproots.txt | cut -d'=' -f2)

# If we want to select a subset of Malardalen benchmarks manually, do it here
# These are copied from the multi-path versions (inout)
#BENCHMARKS := bs bsort100 cnt compress cover crc expint fac fdct

# The source directory of the benchmarks
#SRCDIR := ./src-inout
SRCDIR := ./src

# Use all source .c files found in the source directory
SOURCES := $(wildcard $(SRCDIR)/*.c)

# Only use the selected sources
#SOURCES := $(patsubst %,$(SRCDIR)/%.c,$(BENCHMARKS))

ALL    := $(patsubst $(SRCDIR)/%.c,./%.all,   $(SOURCES))


.PHONY: all clean %.all %.clean cclean
.PRECIOUS: %.sp.elf %.elf %.trace %.sp.trace %.sp.dis %.dis %.sim %.sp.sim

all: $(ALL)


cclean: $(patsubst $(SRCDIR)/%.c,./%.clean,   $(SOURCES))


config.ais:
	platin tool-config -i $(PMLCONFIG) -t ait > $@


#%.all: %.elf %.sp.elf %.trace %.sp.trace %.dis %.sp.dis;
%.all: %.sp.sim %.sp.elf;
	@echo Built $*.

# Plain elf binary, without singlepath
%.elf: $(SRCDIR)/%.c
	patmos-clang -o $@ -mpatmos-disable-ifcvt \
	  -mserialize=$@.pml -mserialize-roots=$(SPROOTS) \
	  $(CFLAGS) $(CONFIG_CLANG) $^ -lm

# Binary with single-path
%.sp.elf %.stats %.log: $(SRCDIR)/%.c
	-patmos-clang -o $*.sp.elf \
	  -mpatmos-singlepath=$(SPROOTS) \
	  -mserialize=$@.pml -mserialize-roots=$(SPROOTS) \
	  -Xllc --debug-only=patmos-singlepath -Xllc -stats \
	  $(CFLAGSSP) $(CONFIG_CLANG) \
	  $^ -lm $(VERBOSE) 2>&1 | tee $*.log | ./cpdot.sh $*
	@grep -E "[0-9]+ patmos-singlepath" $*.log > $*.stats || true


# Disassemble an elf binary
%.dis: %.elf
	patmos-llvm-objdump -d -fpatmos-print-bytes=call $< > $@

%.sim: %.elf
	-timeout 240s pasim -V --flush-caches=main_test $(CONFIG_PASIM) $< 2>&1 | \
	  grep -A2 -E '<($(subst $(comma),|,$(SPROOTS)))>' | \
	  tee $@

%.wcet: %.elf
	for func in $(subst $(comma), ,$(SPROOTS)) ; do \
	  platin wcet -i $<.pml -i $(PMLCONFIG) -e $${func} -b $< --report \
	      --enable-wca --combine-wca ; \
	done | tee $@

	      #--use-trace-facts --trace-entry=$${func} \

%.png: %.dot
	dot -Tpng -o $@ $<


# Delete all files produced by this Makefile for a benchmark
%.clean:
	rm -f $*{,-test}{*.dis,*.elf,.stats,.log,.i,*.o,*.ll,*.bc,*.trace,*.out}
	rm -f $**{.pml,.rec,.sim}



#--debug-file=>(grep -E '$(shell echo $(SPROOTS) | tr ',' '|')' >$@)

%.trace: %.elf
	-pasim $(PASIMDBG) \
	  --mckind=ideal --dckind=ideal --sckind=ideal -G 0 \
	  -V $< > $*.out

%.rec: %.elf
	rm -f tracepipe && mkfifo tracepipe
	pasim --debug=0 --debug-fmt=trace --debug-file=tracepipe \
	  --mckind=ideal --dckind=ideal --sckind=ideal -G 0 \
	  -V $< > /dev/null &
	-timeout 20s platin analyze-trace -i $*.pml -b $*.elf \
	  --trace-file tracepipe --recorders='f:l' | grep 'Loop' > $@
	rm -f tracepipe

