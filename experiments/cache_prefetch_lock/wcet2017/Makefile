
# Experiments for WCET 2017 paper on caching for single-path code
#
# This must be in a subfolder to make the Python scripts happy

# for local configurations, e.g., to override my path to the TACLeBench source
-include config.mk


TACLE?=$(HOME)/source/tacle-bench-play/bench/kernel

# kernel benchmarks
# binarysearch	countnegative	iir		matrix1		quicksort
# bitcount	fac		insertsort	md5		recursion
# bitonic		fft		jfdctint	minver		sha
# bsort		filterbank	lms		pm		st
# complex_updates	fir2dim		ludcmp		prime

# bitcount gives exit value of 1, broken on Patmos?
APP=binarysearch
APP=bsort

SPM=-mpatmos-singlepath=$(APP)_main

CFLAGS= -O2
CFLAGSSP= $(CFLAGS) $(SPM)

all: comp

hello:
	echo "Hello World"
	ls $(TACLE)

# pasim and emulator are off by about 300 clock cycles on binarysearch
# Need to be looked at

comp:
	patmos-clang $(CFLAGS) $(TACLE)/$(APP)/*.c -o a.elf
	pasim -v a.elf 2> abc.txt
	cat abc.txt | grep Cycles:
	patmos-emulator -p a.elf | grep exec_cycles
	patmos-clang $(CFLAGSSP) $(TACLE)/$(APP)/*.c -o a.elf
	pasim -v a.elf 2> abc.txt
	cat abc.txt | grep Cycles:
	patmos-emulator -p a.elf | grep exec_cycles

clean:
	-rm *.txt *.elf

