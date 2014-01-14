flowfacts:
- scope:
    function: quantl
    loop: for.body
  lhs:
  - factor: 1
    program-point:
      function: quantl
      block: for.body
  op: less-equal
  rhs: '30'
  level: bitcode
  origin: llvm.bc
  classification: loop-global
- scope:
    function: my_sin
  lhs:
  - factor: 1
    program-point:
      function: my_sin
      block: while.body15
  op: less-equal
  rhs: '2424'
  origin: llvm.bc
  level: bitcode
