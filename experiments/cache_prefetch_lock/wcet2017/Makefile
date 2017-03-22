
# Experiments for WCET 2017 paper on caching for single-path code
#
# This must be in a subfolder to make the Python scripts happy

# for local configurations, e.g., to override my path to the TACLeBench source
-include config.mk


TACLE?=$(HOME)/source/tacle-bench-play/bench/kernel/binarysearch
#TACLE?=$(HOME)/source/tacle-bench-play/bench/kernel/bitcount

all: comp

hello:
	echo "Hello World"
	ls $(TACLE)

# pasim and emulator are off by about 2000 clock cycles on binarysearch
# Need to be looked at
comp:
	patmos-clang -O0 $(TACLE)/*.c -o a.elf
	pasim -v a.elf 2> abc.txt
	cat abc.txt | grep Cycles:
	patmos-emulator -p a.elf | grep exec_cycles

clean:
	-rm *.txt *.elf

