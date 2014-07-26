---
format: pml-0.1
triple: patmos-unknown-unknown-elf
machine-configuration:
  memories:
    - name: "main"
      size: 67108864
      transfer-size: 16
      read-latency: 3
      read-transfer-time: 4
      write-latency: 3
      write-transfer-time: 4
    - name: "local"
      size: 67108864
      transfer-size: 4
      read-latency: 0
      read-transfer-time: 0
      write-latency: 0
      write-transfer-time: 0
  caches:
    - name: "instruction-cache"
      block-size: 32
      associativity: 8
      size: 4096
      policy: "lru"
      type: "set-associative"
    - name: "stack-cache"
      block-size: 4
      size: 2048
      type: "stack-cache"
  memory-areas:
    - name: "code"
      type: "code"
      memory: "main"
      cache: "instruction-cache"
      address-range:
        min: 0
        max: 0xFFFFFFFF
    - name: "data"
      type: "data"
      memory: "local"
      address-range:
        min: 0
        max: 0xFFFFFFFF


