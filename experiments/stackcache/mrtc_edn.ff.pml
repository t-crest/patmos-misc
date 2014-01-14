flowfacts:
# llvm optimizes to memcpy, bound it with max iterations in program: 150
- scope:
    function: memcpy
    loop: while.body
  lhs:
  - factor: 1
    program-point:
      function: memcpy
      block: while.body
  op: less-equal
  rhs: 150
  level: bitcode
  origin: llvm.bc
  classification: loop-global
- scope:
    function: memcpy
    loop: while.body12
  lhs:
  - factor: 1
    program-point:
      function: memcpy
      block: while.body12
  op: less-equal
  rhs: 150
  level: bitcode
  origin: llvm.bc
  classification: loop-global
- scope:
    function: memcpy
    loop: while.body19
  lhs:
  - factor: 1
    program-point:
      function: memcpy
      block: while.body19
  op: less-equal
  rhs: 150
  level: bitcode
  origin: llvm.bc
  classification: loop-global
