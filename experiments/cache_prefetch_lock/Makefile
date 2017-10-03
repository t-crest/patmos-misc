#
# Makefile in the cache locking evaluation bench.
#
# Author: Daniel Prokesch
#

# We use bash as shell for the makefile.
SHELL=/bin/bash


CC = patmos-clang -mpatmos-method-cache-size=8192 \
     	-mpatmos-stack-cache-block-size=4 -mpatmos-stack-cache-size=1024 \
	-mpatmos-disable-function-splitter -mpatmos-disable-vliw \
	-Xllc -mpatmos-basicblock-align=8

CFLAGS = -g -O2
PASIM = pasim -G0 -m8M --gsize=32M


SPROOTS ?= main

SUBTRACES = $(addsuffix .trace,$(SPROOTS))

TRACE_CMD = $(PASIM) --debug=0 --debug-fmt=trace $< 2>&1 >/dev/null | cut -d' ' -f1
#TRACE_CMD = patemu -r $< | awk '{ printf("%08x\n", $1) }'


null  :=
space := $(null) #
comma := ,


.PHONY: all clean



# Compile an ELF binary from a C file
%.elf: %.c
	$(CC) $(CFLAGS) -o $@ -mpatmos-singlepath=$(SPROOTS) $<

# Disassemble an elf binary
%.dis: %.elf
	patmos-llvm-objdump -d $< > $@

# Generate a compressed instruction address trace
%.trace.gz: %.elf
	$(TRACE_CMD) | gzip > $@

# Simulate a binary and verify constant execution time (manually)
%.sim: %.elf
	$(PASIM) -V $< 2>&1 | grep -A2 -E '<($(subst $(comma),|,$(SPROOTS)))>' | \
	  tee $@

# Extract the start addresses of the functions from the symbol table
# (required for trace analysis)
%.sym: %.elf
	patmos-llvm-objdump -t $< | grep -E "^[0-9a-f]{8} [gl]\s+F\s+.text" | \
	  awk '{print $$1, $$6}' | sort > $@



# extract the subtraces from a compressed, complete trace
%.subtraces: %.sym %.trace.gz
	../extract_subtraces.py $*.sym <(gunzip -c $*.trace.gz) $(SPROOTS)
	touch $@


# Delete all files produced by this Makefile for a benchmark
%.clean:
	@rm -f $*{*.dis,*.elf,.trace.gz,.sim,.subtraces,.sym}
	@rm -f $(SUBTRACES)

