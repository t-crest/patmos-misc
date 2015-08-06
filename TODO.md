TODOs
=====

This is a more or less unsorted list of various, mostly major todos throughout
the tool chain. Most (if not all) of the todos are currently unassigned. If you
want to work on one (or more) of the items, please contact the author of the 
todo entry (see git blame) for further information and coordination.

ISA, General Framework
----------------------

- Define variant of ISA with only 32-bit instructions
  - Variant A: Use existing ISA, adapt compiler and linker to load immediates with
    short ALUi instructions only.
    - Define new linker relocation types, load symbols using multiple ALUi instructions.
    - Define new patterns to load constants
  - Variant B: Adapt ISA to add 16-bit LI low and high nibble, if possible combine
    ALU operation with second load.
    - Same as Variant A, but less instruction overhead
- Make 16 byte alignment of subfunctions a requirement
  - Immediates of call/ret/brcf can be in 16 byte units, quadruples the supported top 
    code address.
  - call-with-return-to-subfunction can be naturally defined with aligned return
  - assembler (paasm and patmos-llc) should ensure alignment


Compiler
--------

- Upgrade to LLVM 3.6 (or 3.7)
  - Should fix compilation issue with clang > 3.4 (?)
  - Further reduce amout of patches outside of Patmos backend
    - Check if new PassManager supports module passes in backend, switch to new
      manager and adapt for machine module passes if necessary.
    - Check for local patches related to merging of debug infos, check if bugfix
      is still necessary
- Debugging Support
  - Test patmos-lldb and integrate it into the build scripts.
    - Support for Stack unwinding?
    - Simulator support?
- Scheduling
  - Check for any advances in the LLVM 3.6 scheduling framework, adapt if possible
  - Improve scheduling of instructions with mutually exclusive predicates.
    - Get information about exclusive predicates from if-conversion or SP-pass, or
      add an analysis pass.
    - Update dependency graph: remove dependencies between independent instructions,
      but add new dependencies to 'true' data-flow successors and predecessors of 
      predicated instructions. Either modify DFG on the fly or adapt DFG construction
      to support predicated instructions.
    - This will primarily improve dual-issue code, but *may* also improve single-issue
      code in rare cases. The overall improvement is probably quite low in any case,
      since it basically only affects if-converted code.
  - Implement a global scheduler
    - Schedule instructions over BB boundaries in order to fill delay slots.
      - Move unpredicated instructions into the delay slot of the branch and
	predicate them with the predicate of the branch.
	- Prefer moving instructions from the most likely target or the current
	  WCET path / the most critical paths.
  - Integrate Delay-slot killer with scheduling strategy. Determine type of 
    branch instruction based on available fill instructions.
  - Enable overlapping of delay-slots of predicated instructions
      (p1) br .LBB1
      (!p1) brnd .LBB2
      (p1) <instr. from .LBB1
    - This is already partially and optionally done by the function splitter
    - WCET analysis (CFG reconstruction, ..) needs to support this kind of code
  - Look into optimizations for very tight loops: do software pipelining for loop condition
    if possible, to move whole loop body into branch delay slots.
  - Make more efficient use of predicates in the code generator
    - Loops with two iterations can use a predicate as loop counter
      - Loops with more iterations can be reduced to such loops by loop unrolling
    - Bool values that are used as guards or in bool operations only can be stored 
      in predicate registers. Check if this can save conversion instructions.
- Automatic use of data scratch-pad
  - Let the compiler use the local scratchpad for register- and predicate spilling in
    the backend
  - Analysis to find data that can be stored in the scratchpad, or that profits
    from fetching to the scratchpad before (multiple) use (over having D$ conflicts or
    by using more efficient (?) burst transfers). Run analysis on bitcode.
- Optimize code size versus performance
  - Tune inliner and loop optimization heuristics to high latencies and caches of Patmos.
    - Avoid inlining large callees multiple times within the same cache persistence scope.


Platin Toolkit, Compiler Integration
------------------------------------

- Run platin pml --validate on generated .pml files in patmos-benchmarks 
  (Malardalen benchmarks,..).
- Data cache analysis
  - Improve platin data cache persistence analysis
    - Handle mixing of unknown, known and somewhat known address accesses
      - Enable invalidation of multiple cache sets
    - Determine number of unknown accesses within a persistence scope,
      bound number of cache misses due to invalidation by unknown access by number 
      of unknown accesses (i.e., a single unknown access (not inside a loop) within
      a cache scope only causes a single (but unknown) cache line to miss, not each
      cache line.
  - Adapt platin to use static address information exported from patmos-llc about
    loads to fields, structs and arrays.
    - Import information and attach to load instructions
    - Adapt cache analysis to use that information to determine cache sets


Simulator
---------

- Delta-Time Simulation: Use deltas to skip stall cycles in simulation.
  - Instead of returning true/false to indicate whether a component (memory, stage,..) stalls,
    return a *minimum* number of stall cycles (can be less than actual stall cycles if stall
    cycles are calculated on the fly, e.g. for page bursts), take the minimum of all components
    as the next delta, and notify components using tick(cycles) of the number of cycles stalled.
  - Speeds up single-core simulation with large latencies to main memory.
  - Make delta-steps optional to get a cycle-by-cycle debug trace if required.
- Multi-core simulation, multi-threaded simulation
  - Adapt memory system to support multiple cores
    - Add core-ID to requests (if necessary)
    - True TDM/bluetree multi-core memory access scheme implementation
  - Extract single cycle iteration code from simulator_t::run() into separate method.
  - Create a new instance of simulator_t per core with shared main memory. Setup IO devices per core.
    Run cycles in lock-step per core. Ensure that the memory is updated only once per cycle.
  - Add a (thread-safe) simulation of the NOC 
  - Create a thread per core, add wait barrier after each cycle.
    Ensure that memory subsystem is thread-safe. Simultanious requests should always be ordered 
    due to the design of the Patmos memory hierarchy!
- Optionally detect bundled instructions in single-issue configuration.

Benchmarks
----------

- Integrate TacleBench Suite
- Get at least some of the MiBench benchmarks to run with platin


Documentation
-------------

- Migrate information from README.patmos files to handbook


