patmos-misc
===========

Config files, scripts, and other stuff for Patmos

## Build Instructions

To build the project, run the following command:

```bash
./misc/build.sh
```

Ensure that all required dependencies are installed before running the script. Refer to the documentation for additional details.

## Script Options

The `build.sh` script supports the following options:

- **`-a`**: Build all targets.
- **`-c`**: Clean builds and rerun configuration.
- **`-r`**: Rerun configuration (resetting CMake cache where applicable).
- **`-h`**: Display the help message and usage instructions.
- **`-i <dir>`**: Set the installation directory to `<dir>`.
- **`-j <n>`**: Pass `-j<n>` to `make` for parallel builds.
- **`-p`**: Create build directories outside the source directories.
- **`-u`**: Update repositories.
- **`-d`**: Dry run; show what would be executed without actually running commands.
- **`-s`**: Show configuration commands for all given targets.
- **`-v`**: Enable verbose output for commands.
- **`-V`**: Make `make` verbose.
- **`-t`**: Run tests after building.
- **`-x`**: Enable shell debugging (`set -x`).
- **`-m`**: Skip building the Patmos emulator.
- **`-e`**: Recreate `build.cfg.dist` from the user configuration section.
- **`-q`**: Download and install pre-built binaries where available, instead of building from source.

## Available Targets

The `build.sh` script supports the following targets:

- **`simulator`**: Builds the Patmos simulator.
- **`gold`**: Builds the gold linker and binutils.
- **`llvm1`**: Builds the LLVM compiler (version 1).
- **`llvm2`**: Builds the LLVM compiler (version 2).
- **`llvm`**: An alias for the `llvm2` target.
- **`newlib`**: Builds the Newlib C library for Patmos.
- **`compiler-rt`**: Builds the compiler runtime for Patmos.
- **`patmos`**: Builds the Patmos tools and emulator.
- **`argo`**: Builds the Argo NoC toolchain.
- **`poseidon`**: Builds the Poseidon WCET analysis tool.
- **`bench`**: Builds and runs benchmarks for Patmos.
- **`rtems`**: Builds the RTEMS real-time operating system for Patmos.
- **`rtems-test`**: Builds and runs RTEMS tests.
- **`rtems-examples`**: Builds RTEMS example applications.
- **`soc-comm`**: Builds the SoC communication libraries.
- **`toolchain1`**: Builds the compiler toolchain using LLVM version 1 (simulator, gold, llvm1, newlib, compiler-rt, etc.).
- **`toolchain2`**: Builds the compiler toolchain using LLVM version 2 (simulator, llvm2, etc.).

## Key Variables

The `build.sh` script uses several variables to control its behavior:

- **`ROOT_DIR`**: The root directory for all repositories. Defaults to the current working directory.
- **`INSTALL_DIR`**: The directory where built files are installed. Defaults to `ROOT_DIR/local`.
- **`BUILDDIR_SUFFIX`**: The suffix for directories containing generated files. Defaults to `/build`.
- **`TOOLCHAIN1_TARGETS`**: The list of targets to build with the `llvm1` compiler.
- **`TOOLCHAIN2_TARGETS`**: The list of targets to build with the `llvm2` compiler.
- **`LLVM_BUILD_TYPE`**: The build type for LLVM (e.g., `Release` or `Debug`).
- **`MAKEJ`**: The number of parallel jobs to use for `make`. Set using the `-j` option.
- **`DO_RUN_TESTS`**: If `true`, tests are run after building.
- **`PREFER_DOWNLOAD`**: If `true`, pre-built binaries are downloaded instead of building from source.

Refer to the `build.sh` script for additional variables and their default values.