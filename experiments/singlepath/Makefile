#
# Makefile in the singlepath evaluation bench.
#
# Author: Daniel Prokesch
#

# We use bash as shell for the makefile.
SHELL=/bin/bash

V ?= 0
ifneq ($V, 0)
  VERBOSE=-v -save-temps
else
  VERBOSE=
endif

REPORT := report.txt

SPROOTS = $$(grep ^$*= sproots.txt | cut -d'=' -f2)

# If we want to select a subset of Malardalen benchmarks manually, do it here
BENCHMARKS=adpcm bs bsort100 cnt compress cover crc duff \
           edn expint fdct fft1 fibcall fir insertsort janne_complex jfdctint \
           lcdnum lms loop3 ludcmp matmult minmax minver ns qsort-exam qurt \
           select sqrt statemate

# The source directory of the benchmarks
SRCDIR := ./src

# Use all source .c files found in the source directory
SOURCES := $(wildcard $(SRCDIR)/*.c)

# Only use the selected sources
#SOURCES := $(patsubst %,$(SRCDIR)/%.c,$(BENCHMARKS))

ELFS   := $(patsubst $(SRCDIR)/%.c,./%.elf,   $(SOURCES))
SPELFS := $(patsubst $(SRCDIR)/%.c,./%.sp.elf,$(SOURCES))


.PHONY: all clean

all: $(SPELFS)


# Plain elf binary, without singlepath
%.elf: $(SRCDIR)/%.c
	patmos-clang -o $@ $< -lm

# Binary with single-path
%.sp.elf %.stats %.log: $(SRCDIR)/%.c
	@echo ================================================================
	@echo Building $*
	@echo ================================================================
	-patmos-clang -o $*.sp.elf \
	  -mpatmos-spconv=$(SPROOTS) \
	  -Xllc --debug-only=patmos-singlepath -Xllc -stats \
	  $< -lm $(VERBOSE) -O1 2> $*.log
	@grep -E "[0-9]+ patmos-singlepath" $*.log > $*.stats || true


# Disassemble an elf binary
%.dis: %.elf
	patmos-llvm-objdump -d $< > $@


# Delete all files produced by this Makefile for a benchmark
%.clean:
	@rm -f $*{*.dis,*.elf,.stats,.log,.i,*.o,*.ll,*.bc}

# Delete all files produced by this Makefile
LAST_MOD_TIME=$$(stat --format="%Y" $(REPORT))
clean: $(patsubst $(SRCDIR)/%.c,./%.clean,$(SOURCES))
	@if [ -f $(REPORT) ]; then \
	    echo Backup report last modified on \
              $$(date --date="@$(LAST_MOD_TIME)"); \
	    mv $(REPORT) $(REPORT).$(LAST_MOD_TIME); \
	fi

