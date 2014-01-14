flowfacts:
- scope:
    function: icrc
    loop: for.body
  lhs:
  - factor: 1
    program-point:
      function: icrc
      block: for.body
  op: less-equal
  rhs: '256'
  level: bitcode
  origin: llvm.bc
  classification: loop-global
- scope:
    function: icrc
    loop: for.body
  lhs:
  - factor: 1
    program-point:
      function: icrc
      block: if.end73
  op: less-equal
  rhs: '40'
  level: bitcode
  origin: llvm.bc
  classification: loop-global
- scope:
    function: icrc1
    loop: for.body
  lhs:
  - factor: 1
    program-point:
      function: icrc1
      block: for.body
  op: less-equal
  rhs: '8'
  level: bitcode
  origin: llvm.bc
  classification: loop-global
