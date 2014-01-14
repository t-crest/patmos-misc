flowfacts:
- scope:
    function: compress
    loop: while.body
  lhs:
  - factor: 1
    program-point:
      function: compress
      block: while.body
  op: less-equal
  rhs: 8
  level: bitcode
  origin: llvm.bc
  classification: loop-global
- scope:
    function: compress
    loop: probe
  lhs:
  - factor: 1
    program-point:
      function: compress
      block: if.end29
  op: less-equal
  rhs: 49
  level: bitcode
  origin: llvm.bc
  classification: loop-global
- scope:
    function: output
    loop: do.body
  lhs:
  - factor: 1
    program-point:
      function: output
      block: land.rhs
  op: less-equal
  rhs: 0
  level: bitcode
  origin: llvm.bc
  classification: loop-global
- scope:
    function: writebytes
    loop: for.body
  lhs:
  - factor: 1
    program-point:
      function: writebytes
      block: for.body
  op: less-equal
  rhs: 1
  level: bitcode
  origin: llvm.bc
  classification: loop-global


