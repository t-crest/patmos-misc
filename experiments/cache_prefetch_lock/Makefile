#
# Makefile in the cache locking evaluation bench.
#
# Author: Daniel Prokesch
#

# We use bash as shell for the makefile.
SHELL=/bin/bash

# Cache evaluation script.
# It invokes the pasim simulator and, based on the instruction trace,
# simulates and analyses cache behavior.
PFSIM := ./cache_eval.py


# The build directory of the debie1 binary
BUILDDIR := ../../../bench/build/Debie1-e/code


BCFILES := class.c.bc classtab.c.bc debie.c.bc health.c.bc hw_if.c.bc measure.c.bc tc_hand.c.bc telem.c.bc harness/harness.c.bc

OBJS = $(addprefix $(BUILDDIR)/CMakeFiles/debie1.dir/,$(BCFILES)) $(BUILDDIR)/patmos/clang/libdebie1-target.a

CC = patmos-clang -mpatmos-method-cache-size=2048 -mpatmos-stack-cache-block-size=4 -mpatmos-stack-cache-size=1024 -mpatmos-disable-function-splitter -mpatmos-disable-vliw #-mpatmos-disable-post-ra
CFLAGS = -fno-builtin -w -g -O2
PASIM = pasim -G0 -m2M


SPROOTS=TC_InterruptService TM_InterruptService HandleHitTrigger HandleTelecommand HandleAcquisition# HandleHealthMonitoring

null  :=
space := $(null) #
comma := ,

# Filename of the global report
REPORT := report.txt

# Do not delete the instruction address trace
.PRECIOUS: %.trace.gz

.PHONY: all clean

# As top level target, create a report
all: $(REPORT)

# The report is created by reading and formatting all the .sim reports.
$(REPORT):
	./report.sh > $@


# The main debie singlepath binary
debie1.sp.elf:
	cd $(BUILDDIR) && $(MAKE)
	$(CC) $(CFLAGS) -o $@ -mpatmos-singlepath=$(subst $(space),$(comma),$(SPROOTS)) $(OBJS)

# Disassemble an elf binary
%.dis: %.elf
	patmos-llvm-objdump -d $< > $@

# Generate a compressed instruction address trace
%.trace.gz: %.elf
	$(PASIM) --debug=0 --debug-fmt=trace $< 2>&1 >/dev/null \
	  | cut -d' ' -f1 | gzip > $@

sptimes: debie1.sp.elf
	$(PASIM) -V $< |& grep -A2 -E '<($(subst $(space),|,$(SPROOTS)))>' | \
	  tee $@

spaddresses: debie1.sp.elf
	patmos-llvm-objdump -t $< | \
	  grep -E '$(subst $(space),|,$(SPROOTS))' | \
	  awk 'BEGIN {OFS="\t"} { print $$1, strtonum("0x"$$5), $$6 }'

funcs.txt: debie1.sp.elf
	./get_functions.sh $< > $@

# Delete all files produced by this Makefile for a benchmark
%.clean:
	@rm -f $*{*.dis,*.elf,.trace*,.dat,.stats,.sim}

# Delete all files produced by this Makefile
LAST_MOD_TIME=$$(stat --format="%Y" $(REPORT))
clean: $(patsubst $(SRCDIR)/%.c,./%.clean,$(SOURCES))
	@if [ -f $(REPORT) ]; then \
	    echo Backup report last modified on \
              $$(date --date="@$(LAST_MOD_TIME)"); \
	    mv $(REPORT) $(REPORT).$(LAST_MOD_TIME); \
	fi

