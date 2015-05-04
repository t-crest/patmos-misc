.PHONY: compile wcet sim cat dirs graphs

.PHONY: main main.sp
.PHONY: main.txt main.sp.txt

CFLAGS = -fno-unroll-loops

CFLAGSSP = $(CFLAGS) \
           -Xopt -disable-early-taildup \
           -Xopt -disable-tail-duplicate \
           -Xopt -enable-tail-merge \
           -Xllc -disable-early-taildup \
           -Xllc -disable-tail-duplicate \
           -Xllc -enable-tail-merge

TRACE_OPTS=--enable-trace-analysis --trace-entry gen_and_search # --check 3
WCA_OPTS=--enable-wca -e gen_and_search

CONFIG=config_dcideal.pml
#CONFIG=config_full.pml

all: dirs compile wcet sim cat

dirs:
	mkdir -p out

compile: main main.sp

sim:
	./pasim-pml -i $(CONFIG) main    -V 2>log.txt
	./pasim-pml -i $(CONFIG) main.sp -V 2>log.sp.txt

wcet: main.txt main.sp.txt

cat:
	cat main.txt
	cat main.sp.txt

main:
	patmos-clang -O2 main.c -mserialize-roots=gen_and_search -mserialize=main.pml -o main

main.sp:
	patmos-clang -O2 main.c -mserialize-roots=gen_and_search -mserialize=main.sp.pml -o main.sp -mpatmos-singlepath=gen_and_search

main.txt:
	platin wcet -i $(CONFIG) $(TRACE_OPTS) $(WCA_OPTS) -i main.pml -b main --report main.txt -o main.wcet.pml --outdir out

main.sp.txt:
	platin wcet -i $(CONFIG) $(TRACE_OPTS) $(WCA_OPTS) -i main.sp.pml -b main.sp --report main.sp.txt -o main.sp.wcet.pml --outdir out

wcet-min:
	platin wcet -i $(CONFIG) --enable-wca -e gen_and_search -i main.pml -b main --report main.txt
	platin wcet -i $(CONFIG) --enable-wca -e gen_and_search -i main.sp.pml -b main.sp --report main.sp.txt

graphs:
	mkdir -p graphs/gen_and_search graphs/gen_and_search.sp graphs/sort graphs/sort.sp graphs/mybsearch graphs/mybsearch.sp
	platin visualize -i main.pml -f gen_and_search -O graphs/gen_and_search
	platin visualize -i main.pml -f sort           -O graphs/sort
	platin visualize -i main.pml -f mybsearch      -O graphs/mybsearch
	platin visualize -i main.sp.pml -f gen_and_search -O graphs/gen_and_search.sp
	platin visualize -i main.sp.pml -f sort_sp_       -O graphs/sort.sp
	platin visualize -i main.sp.pml -f mybsearch_sp_  -O graphs/mybsearch.sp

clean:
	rm -rf main main.sp main.pml main.sp.pml main.wcet.pml main.sp.wcet.pml *.txt
	rm -rf *.o *.i *.ll *.bc *.bak
	rm -rf out graphs
	mkdir out
