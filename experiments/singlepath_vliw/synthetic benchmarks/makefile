
GCC=patmos-clang
OBJDUMP=patmos-llvm-objdump
SP_FUNC=main
CC_FLAGS=-O2
SP_FLAGS=$(CC_FLAGS) -mpatmos-singlepath=$(SP_FUNC)
SIMULATOR=pasim --print-stats=$(SP_FUNC)

all: synth_opt synth_if

synth_opt: synth_opt_nosp synth_opt_sp synth_opt_sp_bundled;

synth_if: synth_if_nosp synth_if_sp synth_if_sp_bundled;

%_nosp: %_nosp.asm %_nosp_bench.txt %_nosp.out;
%_sp: %_sp.asm %_sp_bench.txt %_sp.out;
%_sp_bundled: %_sp_bundled.asm %_sp_bundled_bench.txt %_sp_bundled.out;

%_nosp.out: %.c
	$(GCC) $^ $(CC_FLAGS) -o $@

%_sp.out: %.c
	$(GCC) $^ $(SP_FLAGS) -o $@
	
%_sp_bundled.out: %.c
	$(GCC) $^ $(SP_FLAGS) -Xllc -mpatmos-disable-vliw=false -o $@

%.asm: %.out
	$(OBJDUMP) -d $^ > $@

%_bench.txt: %.out
	# Pipe to 'echo' to ensure exit code is ignored by make
	$(SIMULATOR) $^ 2> $@ | echo ""

clean:
	rm -rf *.out
	rm -rf *.asm
	rm -rf *bench.txt
	 
# Ensure files aren't deleted at end of script
.SECONDARY: