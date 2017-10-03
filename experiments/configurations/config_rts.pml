---
format: pml-0.1
triple: patmos-unknown-unknown-elf
machine-configuration:
  memories:
    - name: "main"
      size: 67108864
      transfer-size: 16
      read-latency: 0
      read-transfer-time: 21
      write-latency: 0
      write-transfer-time: 21
    - name: "local"
      size: 67108864
      transfer-size: 16
      read-latency: 0
      read-transfer-time: 0
      write-latency: 0
      write-transfer-time: 0
  caches:
    - name: "method-cache"
      block-size: 64
      associativity: 32
      size: 4096
      policy: "fifo"
      type: "method-cache"
    - name: "stack-cache"
      block-size: 4
      size: 2048
      type: "stack-cache"
    - name: "data-cache"
      block-size: 32
      associativity: 4
      size: 2048
      policy: "lru"
      type: "set-associative"
  memory-areas:
    - name: "code"
      type: "code"
      memory: "main"
      cache: "method-cache"
      address-range:
        min: 0
        max: 0xFFFFFFFF
    - name: "data"
      type: "data"
      memory: "main"
      cache: "data-cache"
      address-range:
        min: 0
        max: 0xFFFFFFFF


