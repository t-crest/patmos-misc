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
      transfer-size: 4
      read-latency: 0
      read-transfer-time: 0
      write-latency: 0
      write-transfer-time: 0
  caches:
   - name: "stack-cache"
     type: "stack-cache"
     policy: "stack"
     block-size: 4
     size: 128
   - name: "method-cache"
     block-size: 64
     associativity: 32
     size: 2048
     policy: "ideal"
     type: "method-cache"
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


