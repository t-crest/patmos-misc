
# Experiments for WCET 2017 paper on caching for single-path code
#
# This must be in a subfolder to make the Python scripts happy

# for local configurations, e.g., to override my path to the TACLeBench source
-include config.mk

// TACLE?=$(HOME)/data/repository/tacle-bench/bench
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

# those are all benchmarks (except parallel) from TACLeBench
# Which are useful? Which are broken due to byte order? Which cannot be transformed to SP code?
ALLALL=adpcm_dec adpcm_enc ammunition anagram audiobeam binarysearch bitcount bitonic bsort cjpeg_transupp cjpeg_wrbmp complex_updates countnegative cover dijkstra duff epic fac fft filterbank fir2dim fmref g723_enc gsm_dec gsm_encode h264_dec huff_dec huff_enc iir insertsort jfdctint kernells lift lms ludcmp matrix1 md5 minver mpeg2 ndes petrinet pm powerwindow prime quicksort recursion rijndael_dec rijndael_enc sha st statemate susan test3

# Issues: ammunition does not compile
# anagram, bitcount endless loop
# bitonic as SP endless loop
# simply too long: cjpeg_transupp, dijkstra, epic, filterbank, huff_enc, mpeg2, pm, quicksort, recursion, rijndael_dec, rijndael_enc, test3
# compile error: susan

ALLALL=adpcm_dec adpcm_enc audiobeam binarysearch bsort cjpeg_wrbmp complex_updates countnegative cover duff fac fft fir2dim fmref g723_enc gsm_dec gsm_encode h264_dec huff_dec iir insertsort jfdctint kernells lift lms ludcmp matrix1 md5 minver  ndes petrinet powerwindow prime sha st statemate

ALLAPPS=adpcm_dec ludcmp binarysearch bsort
ALLAPPS=$(ALLALL)

#SPM=-mpatmos-singlepath=$(APP)_main
SPM=-mpatmos-singlepath=main

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

tacle-local: $(TACLE_LOCAL)	

# create a local copy of the tacle source directory and
# mark all main() as noinline
$(TACLE_LOCAL):
	git clone https://github.com/tacle/tacle-bench.git	
	mkdir $@
	cp -r tacle-bench/bench/app/* $@
	cp -r tacle-bench/bench/kernel/* $@
	cp -r tacle-bench/bench/sequential/* $@
	cp -r tacle-bench/bench/test/* $@
	./modmain.sh

	# Martin: the following does not work in OS X
	# find $@ -name "*.c" -exec sed -i -e \
	#    "/\(int\|void\)\s\+main/i__attribute__((noinline))" '{}' \+

# not all benchmarks have a main forward declaration. We should fix this.
# Daniel: no worries, just prepend the attribute to the declaration
# However, main is usually not inlined so it should be fine.

# the following does not work for all examples
#	find $@ -name "*.c" -exec sed -i -e \
#	  "s/^\(.*\)\(_Pragma\s*(\s*\"entrypoint\"\s*)\) /__attribute__((noinline)) \1/" '{}' \+

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
	cd $(T-CREST)/patmos; git checkout master
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
	cd $(T-CREST)/patmos; git checkout icache_with_prefetcher
	cp pcache.xml $(T-CREST)/patmos/hardware/config
	# TODO generate RPT, copy to $(T-CREST)/patmos/hardware/src/icache/rpt.txt
	#cd $(T-CREST)/patmos; make clean emulator BOARD=pcache
	#make comp_sp
	#echo "$(APP) pcache sp" > $(APP)_pc_sp.txt
	#$(T-CREST)/patmos/hardware/build/emulator -p a.elf | grep exec_cycles >> $(APP)_pc_sp.txt
	cd $(T-CREST)/patmos; git checkout master


doall: $(TACLE_LOCAL)
	for P in $(ALLAPPS); do $(MAKE) doit APP=$${P}; done;

eval:
	scala eval.scala > data.dat

latex:
	pdflatex -shell-escape genfig.tex
	mv genfig-figure0.pdf example.pdf

clean:
	-rm *.txt *.elf *.dpth *.log *.md5 *.pdf *.auxlock *.aux *.dat
	-rm -r $(TACLE_LOCAL)
	-rm -rf tacle-bench

PAPER?=$(HOME)/paper/tcapapers/2017/spcaching

ms_copy:
	cp *.pdf $(PAPER)



