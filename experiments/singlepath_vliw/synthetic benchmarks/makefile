
GCC=patmos-clang
OBJDUMP=patmos-llvm-objdump
SP_FUNC=main
CC_FLAGS=-O2
SP_FLAGS=$(CC_FLAGS) -mpatmos-singlepath=$(SP_FUNC)
SIMULATOR=pasim --print-stats=$(SP_FUNC)

all: synth_opt synth_if

synth_opt: synth_opt_nosp.asm synth_opt_sp.asm synth_opt_sp_bundled.asm synth_opt_nosp_bench.txt synth_opt_sp_bench.txt synth_opt_sp_bundled_bench.txt

synth_if: synth_if_nosp.asm synth_if_sp.asm synth_if_sp_bundled.asm synth_if_nosp_bench.txt synth_if_sp_bench.txt synth_if_sp_bundled_bench.txt

%_nosp.out: %.c
	$(GCC) $^ $(CC_FLAGS) -o $@

%_sp.out: %.c
	$(GCC) $^ $(SP_FLAGS) -o $@
	
%_sp_bundled.out: %.c
	$(GCC) $^ $(SP_FLAGS) -Xllc -mpatmos-disable-vliw=false -o $@

%.asm: %.out
	$(OBJDUMP) -d $^ > $@

%_bench.txt: %.out
	$(SIMULATOR) $^ 2> $@ | echo ""

clean:
	rm -rf *.out
	rm -rf *.asm
	rm -rf *bench.txt
	 
.PHONY: synth_opt synth_if
	
.SECONDARY: