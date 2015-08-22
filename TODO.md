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
    - Support for Stack unwinding? Define stack layout for unwinding
    - Simulator support?
    - Document in handbook
- Various Code Generation Issues
  - The compiler generates code like this quite often (but not always):
           p1 = cmp r1,r2
      (p1) br .LBB1
	   br .LBB2
      .LBB1
           ....
    It would be more efficient to predicate the second jump with (!p1) and make the first branch
    into a fall-through. Check where this comes from (code layout, branch code generation?,
    function splitter?, ..) and fix/optimize this (avoid peephole optimization, should
    be fixed at source).
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
  - Compare results of scheduler with manual asm implementations of patmos/ctzsi2,c and patmos/udivsi3.c
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
- Result visualization and debugging support
  - The visualize tool does not properly support aiT loop context results.
    - Add a function to core/programinfo.rb to merge timing results for the same program point but
      with different contexts. Properly handle different context-strings and sub-contexts.
    - The semantics of merging contexts might depend on the origin of the timing results. Either define
      semantics of multiple results for different contexts properly (if not done already) and ensure
      all timing sources adhere to that, or make the merge function callback the source plugin (ait,wca,..).
    - Use the merge function to get a single timing entry per origin per (machinecode) edge, display results
    - Alternatively (with an option) display all context results in the graph.
  - Add flow-fact and value-facts from PML to graph output of visualize tool (as option).
  - Add a tool to annotate source code files with WCET results
    - Do colorization of source lines based on WCET path / criticality (generate as HTML, or eclipse plugin,..)
    - Attach found value facts and flow facts to source code, add wcet frequencies and cycles
    - Show cache hit/misses in source code
  - Write trace analysis results to PML
    - Add a tool to compare traces, show 'trace-diff' where one trace has higher frequencies than the other
    - Useful for finding possible underestimations of the analysis
- Distribution
  - Move platin into a git repository on its own, to make it easier for others to fork and adapt platin.
  - (automatically?) extract and copy LLVM headers and implementations as reference code templates to platin repo
    - PML.h, PMLExport.h, PMLImport.h; plus document code snipplets for integrating files into backend
    - ALF backend
    - bitcode flowfact transformation code patches??
    - At least document where to find all the above relevant reference implementations
  - Add documentation to repository
- Reconstruct instructions in BBs from binary
  - A data flow analysis will need semantical information about the instructions in a BB. Enriching
    the PML with all all the required informations will make the files quite large and slow to process.
    As an alternative, the semantics of the instructions should be provided by pml.arch based on
    the instruction opcodes. 
  - Similarly, instruction properties (may-store, may-load) can be provided by pml.arch based on the
    opcode name. The PML thus only needs to contain a list of instruction opcodes per BB, and additional
    information like call- or branch targets that cannot be retrieved from the opcodes alone.
    - This simplifies / decouples the PML export from the platin analysis, as no longer all possible
      meta-information about instructions need to exported, stored and parsed - the exporter does not need
      to be extended whenever the analysis defines new properties.
    - On the downside, the logic of mapping opcodes to instruction properties needs to be duplicated in platin.
      However, some of the logic is duplicated inside LLVM anyway now. It *might* be possible to generate
      instruction description files for platin from LLVMs .td files using a custom tablegen plugin, though.
  - Read opcodes and predicates (and instructions) from binary.
    - In order to avoid storing all operand names in the PML file, we could retrieve the operands from the
      binary. The patmos-llvm disassembler can be used to retrieve the instructions from the binary.
      - Alternatively, we could store the opcode names and constants/symbols as an array at each instruction
	with comparatively low space overhead (compared to a sequence type). The meaning of the
	operands (in, out, inout, guard,..) depends on the opcode.
	- Problem: Constants are partially still only symbols in LLVM. To get the value, they need to
	  be resolved by the extract-symbols tool (which needs to handle relocation types as well!).
	  Extracting the opcodes from the binary avoids this issue.
    - A list of instructions might still be needed in the PML in order to attach analysis results like
      call targets or accessed memory addresses on instructions. It is not necessary to export *all*
      instructions though, only instructions having additional information need to be exported.
      The number of BBs is small enough to export all of them.
    - The bitcode might be handled differently
      - Also skip exporting bitcode instructions. ATM, bitcode instructions are not used for analysis anyway,
	and no mapping is created between bitcode and machine instructions.
      - Relevant instructions could be needed for analysis and/or back-annotation (markers, loads,..) can still
	be exported, similar to machine instructions that have metadata from the compiler attached.
	- Note that ATM relation graphs are created in LLVM already, platin does not recreate them.
	- There is no safe way of precisely mapping instructions without help from the compiler due to scheduling.
      - If a mapping of instructions is required, the relevant instructions could be exported or extracted 
	from the bitcode file as well, e.g. using llvm-dis. However, this requires that the bitcode file(s) are
	kept and passed to platin as well, which complicates the workflow (but this is required for 
	iterative optimization anyway, and in most other cases a mapping to bitcode on instruction level
	will not be needed).
- WCA, cache analysis framework
  - Instantiation of cache analyses should be driven by pml.arch plugin.
    - Make the data-cache analysis use a function block to determine which instruction it needs to analyse / add costs to.
    - Create an 'always-miss' cache analysis for local memory accesses, using the memory 'local'
    - Let the StackCacheAnalysis variants handle stack loads+stores, use memory 'local' to determine latencies (?).
    - Move the code to create M$/D$/I$/S$/.. analyses into @pml.arch, but use generic functions to setup analyses based
      on command line options (?)
- Data cache analysis
  - Improve platin data cache persistence analysis
    - Define an interface to get address-ranges of loads (as well as their width, by opcode)
      - Read from value-facts / attach value-facts to instructions in a pre-pass
    - Handle mixing of unknown, known and range (+stride) address accesses
      - Enable invalidation of multiple cache sets in cache interface.
      - Unknown/array access cause an entry in all abstract cache sets
	- This only works if we either know that
	  - the access happens only *once* within the scope, i.e. it is not within a loop inside the scope
	  - or the access address is unknown but will always go to the *same* location
	- Otherwise we always need to create a conflict, because a single instruction can actually
	  pollute the whole cache if it is executed in a loop with random addresses.
    - Improve handling of unknowns:
      - Do not invalidate cache lines / create conflicts with unknowns
	- Probably best approach: add them to sets, but do not count them for associativity check
      - Determine number of unknown accesses within the persistence scope (executions, not instructions!! 
	i.e., needs loop bounds or at least SCC check) that can actually cause a conflict miss
	- If set size is <= associativity even with unknowns, unknown access is not an issue .. at least
	  for the current scope in question! Need to check scopes for other tags too though!
      - Number of misses for unknown accesses is unbounded (do not include in IPET constraint
	for the scope). Actual number of misses for known accesses in scopes that contain
	at most N unknown accesses (dynamic count) that can cause conflict (number of unknown set entries 
	above associativity) is bounded by <scope-entries> + N (for each unknown access, there is at most
	one additional miss of a known access) within the set *and* over *all* sets!
      - Check related work and prove correctness. Compare theoretical precision with path-based LRU analysis.
    - Improve statistics (minimum cold misses, max conflict misses, ..)
    - Test with path-sensitive conflict detection
  - Adapt platin to use static address information exported from patmos-llc about
    loads to fields, structs and arrays.
    - Export information and attach to load instructions (use value facts) if not already done
    - Adapt cache analysis to use that information to determine cache sets
- Value analysis
  - Implement a value analysis either in LLVM or as DFA in platin.
    - LLVM analysis is more efficient, but does not have access to final symbol values.
    - LLVM already has quite a few analyses available
  - Determine addresses of accesses, if not already determined by LLVM. Use LLVM value facts as inputs
    to analysis
    - Can we get any improvement here? LLVMs facts are probably already quite good for loads that are more or less
      constant, and other loads that access more or less random heap structs are inherently difficult to analyse.
    - We *can* however get some possible improvements by finding *context-sensitive* value facts.
      - We need to determine the context-string length somehow. A fixed level is probably too expensive for ruby
	analyses. Much nicer to split contexts only when there is some actual difference in context-information.
	Determine the contexts in the value-analysis / in LLVM, and use the same contexts in platin / WCA.
      - Split contexts in value analysis (with some max contextstring length). Add a post-pass that merges contexts 
	again if there is no noticable difference in analysis results (load addresses, infeasible paths) resulting 
	from the context values (with some threshold for differences (?)). Export the contexts to platin, either
	explicitly or implicitly by letting platin split contexts whenever there is a relevant flow/value fact for a
	scope.
	- Problem: contexts (and scopes) should be the same for all analyses run within the WCET analysis, otherwise great
	  care and efford needs to be taken to generate correct ILP constraints (if a supporting analysis creates shorter 
	  context-strings) or merge results from different contexts (if a supporting analysis creates more contexts for a 
	  scope). Thus, determine contexts in advance (by value analysis?) and stick to them.
  - Determine infeasible paths
    - Again, this should be a context-sensitve analysis. See above about context-strings.
    - Context-sensitve infeasible paths could help a lot for precision of path-insensitive (cache) analyses.
      We just need to extend the persistence analyses to honor context-sensitive infeasiblitly flow-facts,
      to avoid generating LoadInstructions on infeasible paths. Split contexts based on contexts of flow-facts.
- Proper support for back-annotation and iterative feedback-driven optimization
  - At the moment, support for back-annotation is relatively messy and does not properly support feedback to
    the middle-end opt (i.e. bitcode) passes.
  - Extend PML by 'levels'. Each level has a unique name, and contains a list of functions, BBs and instructions.
    - Each level can either be of type 'bitcode' or 'machinecode'.
      - Either keep the current separation of bitcode and machinecode functions in separate sections, or merge the 
	two sections into a single list.
    - Functions, blocks and instruction IDs are only unique and meaningful within their level. In order to reference
      a function, the reference must contain the name of the level, either explicitly or implicitly.
      - All analyses (WCET,..) and tools (visualize,..) should operate on a given level, i.e., they are initialized
	with a level name or level instance, which is passed on to all internal analysis passes. PML should define
	default level names for common levels, like 'final-mc' for the final (pre-linking) binary (the equivalent to the
	current 'machine-code' section) or 'final-bc' for the final bitcode input to the instruction lowering phase
	(now the current 'bitcode' section), which are used if no level is configured (in the analysis-config sections or
	at the command line).
      - Relation graphs must be used to link functions between two levels. Relation graphs might be used to connect
	any pair of levels, independent of their type (bitcode or machinecode).
      - Is there a need to store the results and graphs of multiple PGO iterations in the same PML file? If so, the
	level names could be used to distinguish iterations. Even if not stored in the same file, the level names
	can be used for a consistency check to avoid inadvertenly mixing up files from different/wrong iterations.
      - Similarly, results like timing and flow-facts must be attached to a level name.
    - Check if LLVM passes now has some support for PGO (profile guided optimization). See how LLVM solves the issues
      of matching profiling results with ever-changing bitcode and machine-code. Try to export WCET profiling information
      as gprof information and use it to drive the LLVM PGO optimizations.
    - Relation graphs might be constructed on the fly between any given level, e.g. when they are needed to perform
      back-annotation. Currently there is no need to export the relation graphs in the compiler (but the compiler
      might perform some cleanup and fixing operations later)
    - Enable export of bitcode-file and PML structure at any bitcode and machine-code level for back-annotation in the next
      phase. Device a (scripting based) framework to iteratively drive patmos-clang and feeding WCET profiling information
      back to the compiler.
    - Implement a framework to run platin analyses as LLVM pass
	- Export the current bitcode as PML. Call platin on the PML file and run the analysis with a target function and
	  a set of arguments/parameters/configurations. Read in the resulting PML and load the analysis results back
	  into LLVM.
	- Optionally stream the PML files directly between the processes. Avoid exporting and loading the bitcode (see
	  TODO 'Reconstructing PML from binary').
    - Find a way to map individual instructions so that data cache analysis results for loads to drive the bypass optimization 
      can be mapped. On the whole, it is probably easier to implement the relevant analyses in LLVM itself, or run
      the cache analyses on the exported PML level directly and avoid the need for back-annotation.
- Improved source code flow transformations
  - Add support for (function-)global loop bounds: _Pragma(loopbound global min N max M)
    - Very simple way to annotate some complex loops (triangle,..)
    - But must handle inlining properly!!
      - Either prevent inling, or let inliner transform annotation into marker-based annotation, or generate marker-based
	flow-fact very early (bitcode pass, or already when parsing pragmas?)
  - Support for parametric loop bounds and expressions: _Pragma(loopbound min 1 max N-1)
    - clang framework to parse pragma expressions ??
  - Support time bounds: _Pragma(loopbound min N max M cycles|msecs)
    - Annotate time until loop condition becomes false
    - In WCET analysis, add edge from loop entry to loop body with max-time as cost, add flow constraint <= 1 on loop header
      - WCET path is: jump into loop just after condition becomes false, do a full loop iteration and then jump out of loop.
      - But can we formulate it in a way that we get the max loop iterations as result of the WCET path analysis?
	- Maybe do a separate analysis of the body to determine max number of iterations, if we want to know this
    - How to store this in PML. Needs special kind of flow fact
    - Can we use this with markers as well?
      - We could specify that after executing marker A, some condition becomes true after at most N cycles/milli-secs.
      - If condition is used as branch-condition, WCET path would be either the normal path from A to cond-test and then false-edge, or
        a new edge with N cost from A to cond-test and then the true-edge.
      - How could this be made to work across loops, like loop time bound?
  - Transformation with relation graphs only works as long as no major structural or control flow decision changes are made.
    For other, higher-level optimization passes, a different technique is required.
    - relation graphs only for backend. Bitcode transformations must be marker-based.
  - Find and finish implementation for source code marker based flow facts
    - Attach markers to variables, use markers for value facts too.
      - pass the variable as parameter to the marker 'function call'. This prevents the compiler
	from removing the variable or change its value before the marker.


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
- Optionally detect and halt on bundled instructions in a single-issue configuration.

Benchmarks
----------

- Integrate TacleBench Suite
- Get at least some of the MiBench benchmarks to run with platin


Documentation
-------------

- Migrate information from README.patmos files to handbook


