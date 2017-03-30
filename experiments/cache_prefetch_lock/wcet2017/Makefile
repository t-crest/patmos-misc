
# Experiments for WCET 2017 paper on caching for single-path code
#
# This must be in a subfolder to make the Python scripts happy

# for local configurations, e.g., to override my path to the TACLeBench source
-include config.mk


TACLE?=$(HOME)/source/tacle-bench-play/bench/kernel
T-CREST?=../../../..

TACLE_LOCAL=./tacle-src-local

# kernel benchmarks
# binarysearch	countnegative	iir		matrix1		quicksort
# bitcount	fac		insertsort	md5		recursion
# bitonic		fft		jfdctint	minver		sha
# bsort		filterbank	lms		pm		st
# complex_updates	fir2dim		ludcmp		prime

# bitcount, fft gives exit value of 1, broken on Patmos?
# bsort, ludcmp are faster with SP, why?
#   because I missed disable-inlining
# minver mit SP code gibt exit != 0

APP=minver
APP=binarysearch
APP=iir
APP=ludcmp

# TODO: add more examples
ALLAPPS=ludcmp binarysearch bsort

#SPM=-mpatmos-singlepath=$(APP)_main
SPM=-mpatmos-singlepath=main

# -mpatmos-disable-function-splitter as not needed in a normal I$# -mpatmos-method-cache-size=8192 maybe not

CFLAGS= -O2 \
        -mpatmos-max-subfunction-size=4096 -mpatmos-preferred-subfunction-size=1024 \
        -Xllc -mpatmos-disable-vliw=false
# -Xopt -disable-inlining
# -mpatmos-disable-function-splitter
CFLAGSSP= $(CFLAGS) $(SPM)


.PHONY: all doall comp doit clean hello tacle-local

all: doall

hello:
	echo "Hello World"
	ls $(TACLE)

tacle-local: $(TACLE_LOCAL)

# create a local copy of the tacle source directory and
# mark all main() as noinline
$(TACLE_LOCAL): $(TACLE)
	cp -r $< $@
	find $@ -name "*.c" -exec sed -i -e \
	  "/\(int\|void\)\s\+main/i__attribute__((noinline))" '{}' \+
	@# replace all entrypoint pragmas with noinline attributes
	@#find $@ -name "*.c" -exec sed -i -e \
	 #   "s/^\(.*\)\(_Pragma\s*(\s*\"entrypoint\"\s*)\) /__attribute__((noinline)) \1/" '{}' \+

# pasim and emulator are off by about 300 clock cycles on binarysearch
# Need to be looked at

comp:
	patmos-clang $(CFLAGS) $(TACLE_LOCAL)/$(APP)/*.c -o a.elf
	pasim -v a.elf 2> abc.txt
	cat abc.txt | grep Cycles:
	patmos-emulator -p a.elf | grep exec_cycles
	patmos-clang $(CFLAGSSP) $(TACLE_LOCAL)/$(APP)/*.c -o a.elf
	pasim -v a.elf 2> abc.txt
	cat abc.txt | grep Cycles:
	patmos-emulator -p a.elf | grep exec_cycles


doit:
	patmos-clang $(CFLAGSSP) $(TACLE_LOCAL)/$(APP)/*.c -o a.elf
	cp *.xml $(T-CREST)/patmos/hardware/config
	cd $(T-CREST)/patmos; make clean emulator BOARD=mcache
	echo "$(APP) mcache" > mc_$(APP).txt
	$(T-CREST)/patmos/hardware/build/emulator -p a.elf | grep exec_cycles >> mc_$(APP).txt
	cd $(T-CREST)/patmos; make clean emulator BOARD=icache
	echo "$(APP) icache" > ic_$(APP).txt
	$(T-CREST)/patmos/hardware/build/emulator -p a.elf | grep exec_cycles >> ic_$(APP).txt

doall: $(TACLE_LOCAL)
	for P in $(ALLAPPS); do $(MAKE) doit APP=$${P}; done;

clean:
	-rm *.txt *.elf

