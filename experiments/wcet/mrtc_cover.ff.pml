---
format:          pml-0.1
triple:          patmos-unknown-unknown-elf
flowfacts:
  - scope:
      function: swi120
    lhs:
      - factor: -120
        program-point:
          marker : 0
      - factor: 1
        program-point:
          marker : 1
    op: less-equal
    rhs: 0
    level: bitcode
    origin: user.bc
  - scope:
      function: swi50
    lhs:
      - factor: -50
        program-point:
          marker : 2
      - factor: 1
        program-point:
          marker : 3
    op: less-equal
    rhs: 0
    level: bitcode
    origin: user.bc
  - scope:
      function: swi10
    lhs:
      - factor: -10
        program-point:
          marker : 4
      - factor: 1
        program-point:
          marker : 5
    op: less-equal
    rhs: 0
    level: bitcode
    origin: user.bc
