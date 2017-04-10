
# Experiments for WCET 2017 paper on caching for single-path code
#
# This must be in a subfolder to make the Python scripts happy


###############################################################################
# Common configuration
#

SHELL = /bin/bash

# to override default paths
-include config.mk

# default paths
T-CREST      ?= ../../../..
PATMOS_HWDIR  = $(T-CREST)/patmos/hardware
TACLE         = ./tacle-bench
TACLE_LOCAL   = ./tacle-src-local

# cache size / burst length setup
XML_SIZE ?= 8k
XML_BURSTLENGTH ?= 4


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


APP?=ludcmp

# those are all benchmarks (except parallel) from TACLeBench
# Which are useful? Which are broken due to byte order? Which cannot be transformed to SP code?
ALLALL=adpcm_dec adpcm_enc ammunition anagram audiobeam binarysearch bitcount bitonic bsort cjpeg_transupp cjpeg_wrbmp complex_updates countnegative cover dijkstra duff epic fac fft filterbank fir2dim fmref g723_enc gsm_dec gsm_encode h264_dec huff_dec huff_enc iir insertsort jfdctint kernells lift lms ludcmp matrix1 md5 minver mpeg2 ndes petrinet pm powerwindow prime quicksort recursion rijndael_dec rijndael_enc sha st statemate susan test3

# Issues: ammunition does not compile
# anagram, bitcount endless loop
# bitonic as SP endless loop
# simply too long: cjpeg_transupp, dijkstra, epic, filterbank, huff_enc, mpeg2, pm, quicksort, recursion, rijndael_dec, rijndael_enc, test3
# compile error: susan

ALLALL=adpcm_dec adpcm_enc audiobeam binarysearch bsort cjpeg_wrbmp complex_updates countnegative cover duff fac fft fir2dim fmref g723_enc gsm_dec gsm_encode h264_dec huff_dec iir insertsort jfdctint kernells lift lms ludcmp matrix1 md5 minver  ndes petrinet powerwindow prime sha st statemate

# TODO: find a small set of benchmarks that execute relative quick
# for playing with the scripts
ALLAPPS?=binarysearch bsort
ALLAPPS?=$(ALLALL)

SPMAIN=main
#SPMAIN=$(APP)_main
SPM=-mpatmos-singlepath=$(SPMAIN)

# -mpatmos-disable-function-splitter as not needed in a normal I$
# -mpatmos-method-cache-size=8192 maybe not

CFLAGS= -O2 \
        -mpatmos-max-subfunction-size=4096 -mpatmos-preferred-subfunction-size=1024 \
        -Xllc -mpatmos-disable-vliw=false
# -Xllc -mpatmos-subfunction-align=32
# -Xopt -disable-inlining
# -mpatmos-disable-function-splitter
CFLAGSSP= $(CFLAGS) $(SPM)


.PHONY: all doall comp doit clean hello tacle-local

all: doall

hello:
	echo "Hello World"
	ls $(TACLE)

###############################################################################
# Get a local copy of the tacle-bench
#

tacle-local: $(TACLE_LOCAL)

$(TACLE):
	-git clone https://github.com/tacle/tacle-bench.git $@

# create a local copy of the tacle source directory and
# mark all main() as noinline
$(TACLE_LOCAL): $(TACLE)
	mkdir -p $@
	cp -r $</bench/app/* $@
	cp -r $</bench/kernel/* $@
	cp -r $</bench/sequential/* $@
	cp -r $</bench/test/* $@
# fix for sed incompatibility between GNU and BSD (Mac OS X)
# Maybe we should write a few lines of Scala and stop using sed
ifeq ($(TERM_PROGRAM),$(filter $(TERM_PROGRAM), Apple_Terminal iTerm.app))
	./modmain.sh
else
	find $@ -name "*.c" -exec sed -i'.orig' -e \
	   "/\(int\|void\)\s\+main/i\
	   __attribute__((noinline))" '{}' \+
endif



###############################################################################
# Hardware/Emulator
#
patmos_emu_ic_prefetch: XML_TYPE = prefetch
patmos_emu_ic_prefetch: $(APP).rpt cache.xml
	cd $(T-CREST)/patmos && git checkout icache_with_prefetcher
	cp cache.xml $(PATMOS_HWDIR)/config/cache_$(XML_TYPE).xml
	cp $< $(PATMOS_HWDIR)/src/icache/rpt.txt
	$(MAKE) -C $(T-CREST)/patmos clean emulator BOARD=cache_$(XML_TYPE)
	cp $(PATMOS_HWDIR)/build/emulator $@



cache.xml: template.xml
	sed \
	  -e "s/XML_BURSTLENGTH/$(XML_BURSTLENGTH)/" \
	  -e "s/XML_TYPE/$(XML_TYPE)/" \
	  -e "s/XML_SIZE/$(XML_SIZE)/" \
	  -e "s/XML_ASSOC/$(XML_ASSOC)/" \
	  $< > $@


###############################################################################
# Compilation
#

$(APP).elf: $(TACLE_LOCAL)
	patmos-clang $(CFLAGS) $(TACLE_LOCAL)/$(APP)/*.c -o $@



###############################################################################
# Generation of the prefetch table
#

# command to generate an instruction trace (pasim is faster)
TRACE_CMD = pasim -G0 -m8M --gsize=32M --debug=0 --debug-fmt=trace \
	    $< 2>&1 >/dev/null | cut -d' ' -f1
#TRACE_CMD = patmos-emulator -r $< | awk '{ printf("%08x\n", $1) }'

%.rpt: %.sym %.sptrace
	#TODO  cache [+line] size
	python2 ../mktables.py --rpt -e $^ > $@


# Extract the start addresses of the functions from the symbol table
# (required for trace analysis)
%.sym: %.elf
	patmos-llvm-objdump -t $< | grep -E "^[0-9a-f]{8} [gl]\s+F\s+.text" | \
	  awk '{print $$1, $$6}' | sort > $@


# Generate a compressed instruction address trace
%.trace.gz: %.elf
	$(TRACE_CMD) | gzip > $@


# extract the subtraces from a compressed, complete trace
%.sptrace: %.sym %.trace.gz
	../extract_subtraces.py $*.sym <(gunzip -c $*.trace.gz) $(SPMAIN)
	mv main.trace $@


###############################################################################

.PHONY: report-prefetch


report-prefetch: $(APP)_pc_sp.txt

# target-specific variables
$(APP)_pc_sp.txt: LABEL = pcache sp
$(APP)_pc_sp.txt: XML_TYPE = prefetch
$(APP)_pc_sp.txt: XML_ASSOC = 1
$(APP)_pc_sp.txt: CFLAGS = \
  -O2 -g \
  -mpatmos-disable-function-splitter \
  -Xllc -mpatmos-disable-vliw=false \
  -mpatmos-singlepath=$(SPMAIN)


$(APP)_pc_sp.txt: $(APP).elf  patmos_emu_ic_prefetch
	echo "$(APP) $(LABEL)" >> $@
	./patmos_emu_ic_prefetch -p $< | grep exec_cycles >> $@


###############################################################################

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

comp_normal:
	patmos-clang $(CFLAGS) $(TACLE_LOCAL)/$(APP)/*.c -o a.elf

comp_sp:
	patmos-clang $(CFLAGSSP) $(TACLE_LOCAL)/$(APP)/*.c -o a.elf

doit:
	cd $(T-CREST)/patmos; git checkout master; git checkout b99441ede979f4c
	cp *.xml $(T-CREST)/patmos/hardware/config
	cd $(T-CREST)/patmos; make clean emulator BOARD=mcache
	make comp_normal
	echo "$(APP) mcache np" > $(APP)_mc_np.txt
	$(T-CREST)/patmos/hardware/build/emulator -p a.elf | grep exec_cycles >> $(APP)_mc_np.txt
	make comp_sp
	echo "$(APP) mcache sp" > $(APP)_mc_sp.txt
	$(T-CREST)/patmos/hardware/build/emulator -p a.elf | grep exec_cycles >> $(APP)_mc_sp.txt
	cd $(T-CREST)/patmos; make clean emulator BOARD=icache
	make comp_normal
	echo "$(APP) icache np" > $(APP)_ic_np.txt
	$(T-CREST)/patmos/hardware/build/emulator -p a.elf | grep exec_cycles >> $(APP)_ic_np.txt
	make comp_sp
	echo "$(APP) icache sp" > $(APP)_ic_sp.txt
	$(T-CREST)/patmos/hardware/build/emulator -p a.elf | grep exec_cycles >> $(APP)_ic_sp.txt
	$(MAKE) report-prefetch
	cd $(T-CREST)/patmos; git checkout master



###############################################################################

doall: $(TACLE_LOCAL)
	for P in $(ALLAPPS); do $(MAKE) doit APP=$${P}; done;

eval:
	scala eval.scala > data.dat

latex:
	pdflatex -shell-escape genfig.tex
	mv genfig-figure0.pdf example.pdf

clean:
	rm -f *.txt *.elf *.dpth *.log *.md5 *.pdf *.auxlock *.aux *.dat *.rpt *.sym
	rm -f cache.xml
	rm -rf $(TACLE_LOCAL)
	rm -rf $(TACLE)

PAPER?=$(HOME)/paper/tcapapers/2017/spcaching

ms_copy:
	cp *.pdf $(PAPER)



