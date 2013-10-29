---
format: pml-0.1
triple: patmos-unknown-unknown-elf
machine-configuration:
  memories:
    - name: "main"
      size: 67108864
      transfer-size: 8
      read-latency: 4
      read-transfer-time: 1
      write-latency: 4
      write-transfer-time: 1
    - name: "local"
      size: 67108864
      transfer-size: 8
      read-latency: 0
      read-transfer-time: 0
      write-latency: 0
      write-transfer-time: 0
  caches:
    - name: "data-cache"
      block-size: 8
      associativity: 2
      size: 2048
      policy: "lru"
      type: "set-associative"
    - name: "method-cache"
      block-size: 256
      associativity: 8
      size: 2048
      policy: "fifo"
      type: "method-cache"
      attributes:
        - key:   "preferred-subfunction-size"
          value: 128
        - key:   "max-subfunction-size"
          value: 256
    - name: "stack-cache"
      block-size: 4
      size: 1024
      type: "stack-cache"
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

