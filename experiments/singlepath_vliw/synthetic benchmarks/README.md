Dual-Issue Single-path Synthetic Benchmarks
=======================

This folder contains a set of synthetic benchmark programs to excercise generation of dual-issue single-path code.
Each program is self-contained in a `.c` file and can be automatically compiled, disassembled, and benchmarked.

### How To Use

The included `makefile` manages everything. To compile, disassemble, and benchmark all programs simply open a terminal in this folder and run the command:

```sh
make -j
```

For each programs, 3 different versions are compiled: traditional code (`nosp`), single-path code without any bundling (`sp`), and single-path code with bundling (`sp_bundled`.)
For each version of a program 3 file are created:

- `*.asm`: The disassembly of the program.
- `*.out`: The compiled program.
- `*_bench.txt`: Statistics produced by `pasim` after running the program.

In total, for each program, 9 files are produced (3 versions x 3 files per version).

To only build and benchmark one of the programs, simply supply its name to `make` (without `.c`):

```sh
# Build and benchmark all versions of the synth_opt.c program
make -j synth_opt 
```

To only build and benchmark on version of one program, simply add the appropriate postfix (i.e. `_` followed by the version moniker):
```sh
# Builds and benchmarks only the single-path (no bundling) version of the synth_opt.c program
make -j synth_opt_sp 
```

