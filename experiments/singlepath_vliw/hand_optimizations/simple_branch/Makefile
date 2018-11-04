
OPT = -O2
DEL = rm -f


all: main.o main_optimized_objdump.asm

main.bc: main.c
	patmos-clang -S $? -o main.bc $(OPT)
	
main.asm: main.bc
	patmos-llc $? -o main.asm -mpatmos-singlepath=init_func $(OPT)
	
main.o: main.asm
	patmos-clang main.asm -o main.o
	
main_optimized.o: main_optimized.asm
	patmos-clang main_optimized.asm -o main_optimized.o
	
main_optimized_objdump.asm: main_optimized.o
	patmos-llvm-objdump -d main_optimized.o > main_optimized_objdump.asm

stat_main: main.o
	pasim main.o --print-stats init_func
stat_optimized: main_optimized.o
	pasim main_optimized.o --print-stats init_func
	
.PHONY: clean
clean:
	$(DEL) main.bc
	$(DEL) main.asm
	$(DEL) main.o
	$(DEL) main_optimized_objdump.asm
	$(DEL) main_optimized.o