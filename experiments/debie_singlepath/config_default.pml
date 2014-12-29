---
format: pml-0.1
triple: patmos-unknown-unknown-elf
machine-configuration:
  memories:
    - name: "main"
      size: 0x2000000
      transfer-size: 16
      read-latency: 3
      read-transfer-time: 4
      write-latency: 3
      write-transfer-time: 4
    - name: "local"
      size: 2048
      transfer-size: 4
      read-latency: 0
      read-transfer-time: 0
      write-latency: 0
      write-transfer-time: 0
  caches:
    - name: "method-cache"
      block-size: 8
      associativity: 16
      size: 4096
      policy: "fifo"
      type: "method-cache"
    - name: "stack-cache"
      block-size: 4
      size: 2048
      type: "stack-cache"
  memory-areas:
    - name: "code"
      type: "code"
      memory: "main"
      cache: "method-cache"
      address-range:
        min: 0
        max: 0x200000
    - name: "data"
      type: "data"
      memory: "main"
      address-range:
        min: 0
        max: 0x2000000
      attributes:
        - key: "heap-end"
          value: 0x1000000
        - key: "stack-base"
          value: 0x2000000
        - key: "shadow-stack-base"
          value: 0x1f80000
