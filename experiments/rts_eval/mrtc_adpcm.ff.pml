---
format:          pml-0.1
triple:          patmos-unknown-unknown-elf
flowfacts:       
  - scope:
      function: main
    lhs:
      - factor: 1
        program-point:
          marker : 1
      - factor: -3
        program-point:
          marker : 0
    op: less-equal
    rhs: 0
    level: bitcode
    origin: user.bc
  - scope:
      function: main
    lhs:
      - factor: 1
        program-point:
          marker : 3
      - factor: -30
        program-point:
          marker : 2
    op: less-equal
    rhs: 0
    level: bitcode
    origin: user.bc
  - scope:
      function: main
    lhs:
      - factor: -2424
        program-point:
          marker : 4
      - factor: 1
        program-point:
          marker : 5
    op: less-equal
    rhs: 0
    level: bitcode
    origin: user.bc
