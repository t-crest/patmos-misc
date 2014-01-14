flowfacts:
- scope:
    function: binary_search
    loop: while.body
  lhs:
  - factor: 1
    program-point:
      function: binary_search
      block: if.else
  op: less-equal
  rhs: 4
  level: bitcode
  origin: llvm.bc
  classification: loop-global
