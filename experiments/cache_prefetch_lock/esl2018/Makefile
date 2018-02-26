
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
XML_SIZE ?= 4096
XML_BURSTLENGTH ?= 4
XML_REPL ?= fifo


# bitcount, fft gives exit value of 1, broken on Patmos?
# minver with SP code gives exit != 0


APP?=ludcmp

# those are all benchmarks (except parallel) from TACLeBench
# Which are useful? Which are broken due to byte order? Which cannot be transformed to SP code?
ALLALL=adpcm_dec adpcm_enc ammunition anagram audiobeam binarysearch bitcount bitonic bsort cjpeg_transupp cjpeg_wrbmp complex_updates countnegative cover dijkstra duff epic fac fft filterbank fir2dim fmref g723_enc gsm_dec gsm_encode h264_dec huff_dec huff_enc iir insertsort jfdctint kernells lift lms ludcmp matrix1 md5 minver mpeg2 ndes petrinet pm powerwindow prime quicksort recursion rijndael_dec rijndael_enc sha st statemate susan test3

# Issues: ammunition does not compile
# anagram, bitcount endless loop
# bitonic as SP endless loop
# simply too long: cjpeg_transupp, dijkstra, epic, filterbank, huff_enc, mpeg2, pm, quicksort, recursion, rijndael_dec, rijndael_enc, test3
# compile error: susan

# Single path (with prefetch issue) (on Mac): audiobeam
# Issue probably with 2-way cache?: fir2dim
# Takes too long: fft
# Even simulation with pasim takes too long: fmref

# following used for eval (under Ubuntu)
ALLALL =adpcm_dec adpcm_enc audiobeam binarysearch bsort cjpeg_wrbmp complex_updates countnegative cover duff fac fft fir2dim fmref g723_enc gsm_dec gsm_encode h264_dec huff_dec iir insertsort jfdctint kernells lift lms ludcmp matrix1 md5 minver  ndes petrinet powerwindow prime sha st statemate

# Trouble with: gsm_encode
# following used on the Mac
ALLALL=adpcm_dec adpcm_enc binarysearch bsort cjpeg_wrbmp complex_updates countnegative cover duff fac g723_enc gsm_dec h264_dec huff_dec iir insertsort jfdctint lift lms ludcmp matrix1 md5 minver  ndes petrinet powerwindow prime sha st statemate

# TODO: find a small set of benchmarks that execute relative quick
# for playing with the scripts
#ALLAPPS?=adpcm_dec binarysearch complex_updates cover h264_dec
ALLAPPS?=$(ALLALL)

SPMAIN=main
#SPMAIN=$(APP)_main
SPM=-mpatmos-singlepath=$(SPMAIN)

CFLAGS = -O2 -g -Xllc -mpatmos-disable-vliw=false

.PHONY: all doall comp doit clean tacle-local

all: doall

FORCE:


###############################################################################
# Get a local copy of the tacle-bench
#

tacle-local: $(TACLE_LOCAL)

$(TACLE):
	-git clone https://github.com/tacle/tacle-bench.git $@
	cd $@ && git checkout fcabf4630cb239f34f37a03ce7d93c563b65c897

# create a local copy of the tacle source directory and
# mark all main() as noinline
$(TACLE_LOCAL): $(TACLE)
	mkdir -p $@
	cp -r $</bench/app/* $@
	cp -r $</bench/kernel/* $@
	cp -r $</bench/sequential/* $@
	cp -r $</bench/test/* $@
	./modmain.sh



###############################################################################
# Hardware/Emulator
#
patmos_emu_prefetch.$(APP): XML_TYPE = prefetch
patmos_emu_prefetch.$(APP): XML_ASSOC = 1
patmos_emu_prefetch.$(APP): $(APP).rpt pcache.xml
	cd $(T-CREST)/patmos && git checkout icache_with_prefetcher
	cp pcache.xml $(PATMOS_HWDIR)/config/
	cp $< $(PATMOS_HWDIR)/src/icache/rpt.txt
	$(MAKE) -C $(T-CREST)/patmos clean emulator BOARD=pcache
	cp $(PATMOS_HWDIR)/build/emulator $@


patmos_emu_mc: XML_TYPE = method
patmos_emu_mc: XML_ASSOC = 16
patmos_emu_mc: mcache.xml
	# cd $(T-CREST)/patmos && git checkout a173b6de37195f7a1096cc8c9a10936ad5f1ca75
	cd $(T-CREST)/patmos && git checkout esl2018
	cp mcache.xml $(PATMOS_HWDIR)/config/
	$(MAKE) -C $(T-CREST)/patmos clean emulator BOARD=mcache
	cp $(PATMOS_HWDIR)/build/emulator $@


patmos_emu_ic: XML_TYPE = line
patmos_emu_ic: XML_ASSOC = 1
patmos_emu_ic: icache.xml
	# cd $(T-CREST)/patmos && git checkout a173b6de37195f7a1096cc8c9a10936ad5f1ca75
	cd $(T-CREST)/patmos && git checkout esl2018
	cp icache.xml $(PATMOS_HWDIR)/config/
	$(MAKE) -C $(T-CREST)/patmos clean emulator BOARD=icache
	cp $(PATMOS_HWDIR)/build/emulator $@

# 2-way instruction cache not in master branch
patmos_emu_lc: XML_TYPE = line
patmos_emu_lc: XML_ASSOC = 2
patmos_emu_lc: XML_REPL = lru
patmos_emu_lc: lcache.xml
	cd $(T-CREST)/patmos && git checkout icache_with_prefetcher
	cp lcache.xml $(PATMOS_HWDIR)/config/
	$(MAKE) -C $(T-CREST)/patmos clean emulator BOARD=lcache
	cp $(PATMOS_HWDIR)/build/emulator $@




%cache.xml: template.xml
	sed \
	  -e "s/XML_BURSTLENGTH/$(XML_BURSTLENGTH)/" \
	  -e "s/XML_TYPE/$(XML_TYPE)/" \
	  -e "s/XML_SIZE/$(XML_SIZE)/" \
	  -e "s/XML_ASSOC/$(XML_ASSOC)/" \
	  -e "s/XML_REPL/$(XML_REPL)/" \
	  $< > $@


###############################################################################
# Compilation
#
# MS: why do there exist 3 function splitter parameters for actually just
# two useful values: max and preferred? Which one are used and how?

MSIZE=$(XML_SIZE)

$(APP).nofs.sp.elf: $(TACLE_LOCAL)
	patmos-clang $(CFLAGS) $(TACLE_LOCAL)/$(APP)/*.c -o $@ \
	  -mpatmos-disable-function-splitter \
	  -mpatmos-singlepath=$(SPMAIN)

$(APP).sp.elf: $(TACLE_LOCAL)
	patmos-clang $(CFLAGS) $(TACLE_LOCAL)/$(APP)/*.c -o $@ \
	  -mpatmos-max-subfunction-size=$(MSIZE) \
	  -mpatmos-preferred-subfunction-size=$(MSIZE) \
	  -mpatmos-method-cache-size=$(MSIZE) \
	  -mpatmos-singlepath=$(SPMAIN)

$(APP).nofs.elf: $(TACLE_LOCAL)
	patmos-clang $(CFLAGS) $(TACLE_LOCAL)/$(APP)/*.c -o $@ \
	  -mpatmos-disable-function-splitter

$(APP).elf: $(TACLE_LOCAL)
	patmos-clang $(CFLAGS) $(TACLE_LOCAL)/$(APP)/*.c -o $@ \
	  -mpatmos-max-subfunction-size=$(MSIZE) \
	  -mpatmos-preferred-subfunction-size=$(MSIZE) \
	  -mpatmos-method-cache-size=$(MSIZE)

###############################################################################
# Generation of the prefetch table
#

# command to generate an instruction trace (pasim is faster)
TRACE_CMD = pasim -G0 -m8M --gsize=32M --debug=0 --debug-fmt=trace \
	    $< 2>&1 >/dev/null | cut -d' ' -f1
#TRACE_CMD = patemu -r $< | awk '{ printf("%08x\n", $1) }'

%.rpt: %.sym %.sptrace
	python2 ../mktables.py --rpt -e \
	  -s $(shell dc -e "$(XML_BURSTLENGTH) 4 *p") \
	  -l $(shell dc -e "$(XML_SIZE) $(XML_BURSTLENGTH) /4/p") \
	  $^ > $@


# Extract the start addresses of the functions from the symbol table
# (required for trace analysis)
%.sym: %.nofs.sp.elf
	patmos-llvm-objdump -t $< | grep -E "^[0-9a-f]{8} [gl]\s+F\s+.text" | \
	  awk '{print $$1, $$6}' | sort > $@

# Generate a compressed instruction address trace
%.trace.gz: %.nofs.sp.elf
	$(TRACE_CMD) | gzip > $@


# extract the subtraces from a compressed, complete trace
%.sptrace: %.sym %.trace.gz
	../extract_subtraces.py $*.sym <(gunzip -c $*.trace.gz) $(SPMAIN)
	mv main.trace $@


###############################################################################

.PHONY: report


report: $(APP)_mc_sp.txt \
	$(APP)_ic_sp.txt \
	$(APP)_mc_np.txt \
	$(APP)_pc_sp.txt \
	$(APP)_ic_np.txt \
	$(APP)_lc_sp.txt
	cd $(T-CREST)/patmos; git checkout master

# target-specific variables
$(APP)_pc_sp.txt: LABEL = pcache sp
$(APP)_pc_sp.txt: $(APP).nofs.sp.elf  patmos_emu_prefetch.$(APP)
	echo "$(APP) $(LABEL)" >> $@
	./patmos_emu_prefetch.$(APP) -p $< | grep exec_cycles >> $@

$(APP)_mc_sp.txt: LABEL = mcache sp
$(APP)_mc_sp.txt: $(APP).sp.elf  patmos_emu_mc
	echo "$(APP) $(LABEL)" >> $@
	./patmos_emu_mc -p $< | grep exec_cycles >> $@

$(APP)_ic_sp.txt: LABEL = icache sp
$(APP)_ic_sp.txt: $(APP).nofs.sp.elf  patmos_emu_ic
	echo "$(APP) $(LABEL)" >> $@
	./patmos_emu_ic -p $< | grep exec_cycles >> $@

$(APP)_lc_sp.txt: LABEL = lcache sp
$(APP)_lc_sp.txt: $(APP).nofs.sp.elf  patmos_emu_lc
	echo "$(APP) $(LABEL)" >> $@
	./patmos_emu_lc -p $< | grep exec_cycles >> $@

$(APP)_mc_np.txt: LABEL = mcache np
$(APP)_mc_np.txt: $(APP).elf  patmos_emu_mc
	echo "$(APP) $(LABEL)" >> $@
	./patmos_emu_mc -p $< | grep exec_cycles >> $@

$(APP)_ic_np.txt: LABEL = icache np
$(APP)_ic_np.txt: $(APP).nofs.elf  patmos_emu_ic
	echo "$(APP) $(LABEL)" >> $@
	./patmos_emu_ic -p $< | grep exec_cycles >> $@

$(APP)_lc_np.txt: LABEL = lcache np
$(APP)_lc_np.txt: $(APP).nofs.elf  patmos_emu_lc
	echo "$(APP) $(LABEL)" >> $@
	./patmos_emu_lc -p $< | grep exec_cycles >> $@

###############################################################################


doall: $(TACLE_LOCAL)
	for P in $(ALLAPPS); do $(MAKE) report APP=$${P}; done;

eval:
	scala eval.scala sp pcache mcache > data.dat
	pdflatex -shell-escape genfig.tex
	mv genfig-figure0.pdf sp_pc_mc.pdf
	scala eval.scala sp pcache icache > data.dat
	pdflatex -shell-escape genfig.tex
	mv genfig-figure0.pdf sp_pc_ic.pdf

unused:
	scala eval.scala np mcache icache > data.dat
	pdflatex -shell-escape genfig.tex
	mv genfig-figure0.pdf np_mc_ic.pdf
	scala eval.scala sp mcache icache > data.dat
	pdflatex -shell-escape genfig.tex
	mv genfig-figure0.pdf sp_mc_ic.pdf
	scala eval.scala sp lcache icache > data.dat
	pdflatex -shell-escape genfig.tex
	mv genfig-figure0.pdf sp_lc_ic.pdf

clean:
	rm -f *.txt *.elf *.dpth *.log *.md5 *.pdf *.auxlock *.aux *.dat *.rpt *.sym *.sizes
	rm -f *cache.xml
	rm -f patmos_emu_*
	rm -rf $(TACLE_LOCAL)
	# don't need to delete the tacle-bench repo
	# But MS wants to clean all stuff
	rm -rf $(TACLE)

# MS private targets to simplify life

PAPER?=$(HOME)/paper/tcapapers/2017/patpref-jnl

sizes:
	for x in *.elf ; do echo $$x $$(./calc_size.sh $$x) ; done > sizes.txt

ms_copy:
	cp *.pdf $(PAPER)
