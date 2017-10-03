---
format:          pml-0.1
triple:          patmos-unknown-unknown-elf
flowfacts:       
  - scope:
      function: compress
    lhs:
      - factor: 1
        program-point:
          marker : 1
      - factor: -49
        program-point:
          marker : 0
    op: less-equal
    rhs: 0
    level: bitcode
    origin: user.bc
  - scope:
      function: compress
    lhs:
      - factor: 1
        program-point:
          marker : 2
      - factor: -1
        program-point:
          marker : 1
    op: less-equal
    rhs: 0
    level: bitcode
    origin: user.bc
  - scope:
      function: compress
    lhs:
      - factor: 1
        program-point:
          marker : 3
    op: less-equal
    rhs: 0
    level: bitcode
    origin: user.bc
#  - scope:
#      function: output
#    lhs:
#      - factor: 1
#        program-point:
#          marker : 4
#    op: less-equal
#    rhs: 0
#    level: bitcode
#    origin: user.bc
#  - scope:
#      function: writebytes
#    lhs:
#      - factor: 1
#        program-point:
#          marker : 5
#    op: less-equal
#    rhs: 0
#    level: bitcode
#    origin: user.bc
