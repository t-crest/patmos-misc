.PHONY: compile wcet sim cat

.PHONY: main main.sp
.PHONY: main.txt main.sp.txt

all: compile wcet sim cat

compile: main main.sp

sim:
	./pasim-pml -i config_full.pml main
	./pasim-pml -i config_full.pml main.sp

wcet: main.txt main.sp.txt

cat:
	cat main.txt
	cat main.sp.txt

main:
	patmos-clang -O2 main.c -mserialize=main.pml -o main

main.sp:
	patmos-clang -O2 main.c -mserialize=main.sp.pml -o main.sp -mpatmos-singlepath=gen_and_search

main.txt:
	platin wcet -i config_full.pml --enable-wca -e gen_and_search -i main.pml -b main --report main.txt

main.sp.txt:
	platin wcet -i config_full.pml --enable-wca -e gen_and_search -i main.sp.pml -b main.sp --report main.sp.txt
