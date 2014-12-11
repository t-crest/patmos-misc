---
format: pml-0.1
triple: patmos-unknown-unknown-elf
machine-configuration:
  memories:
    - name: "local"
      size: 67108864
      transfer-size: 4
      read-latency: 0
      read-transfer-time: 0
      write-latency: 0
      write-transfer-time: 0
  caches:
    - name: "branch-predictor"
      type: "standard"
      policy: "lru"
      associativity: 1
      block-size: 1
      size: 16
  memory-areas:
    - name: "code"
      type: "code"
      memory: "local"
      address-range:
        min: 0
        max: 0xFFFFFFFF
    - name: "data"
      type: "data"
      memory: "local"
      address-range:
        min: 0
        max: 0xFFFFFFFF


