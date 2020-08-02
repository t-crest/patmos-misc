
GCC=patmos-clang
OBJDUMP=patmos-llvm-objdump
PROG=synth_opt.c
CC_FLAGS=-O2
SIMULATOR=pasim --print-stats=main

all: a_sp.out.asm a_nosp.out.asm a_sp.out.txt a_nosp.out.txt

sim: a_sp.out.txt a_nosp.out.txt

a_sp.out: $(PROG)
	$(GCC) $(PROG) $(CC_FLAGS) -mpatmos-singlepath=main -o a_sp.out
	
a_nosp.out: $(PROG)
	$(GCC) $(PROG) $(CC_FLAGS) -o a_nosp.out
	
a_sp.out.asm: a_sp.out
	$(OBJDUMP) -d a_sp.out > a_sp.out.asm
	
a_nosp.out.asm: a_nosp.out
	$(OBJDUMP) -d a_nosp.out > a_nosp.out.asm
	
a_sp.out.txt: a_sp.out
	$(SIMULATOR) a_sp.out 2> a_sp.out.txt | echo " "
	
a_nosp.out.txt: a_nosp.out
	$(SIMULATOR) a_nosp.out 2> a_nosp.out.txt | echo " "