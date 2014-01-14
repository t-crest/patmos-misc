flowfacts:
- scope:
    function: BubbleSort
    loop: for.cond1.preheader
  lhs:
  - factor: 1
    program-point:
      function: BubbleSort
      block: for.end
  op: less-equal
  rhs: 99
  level: bitcode
  origin: llvm.bc
  classification: loop-global
- scope:
    function: BubbleSort
    loop: for.cond1.outer
  lhs:
  - factor: 1
    program-point:
      function: BubbleSort
      block: for.cond1
  op: less-equal
  rhs: 99
  level: bitcode
  origin: llvm.bc
  classification: loop-local
