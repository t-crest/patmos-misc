---
format: pml-0.1
triple: patmos-unknown-unknown-elf
machine-configuration:
  memories:
    - name: "main"
      size: 67108864
      transfer-size: 8
      read-latency: 0
      read-transfer-time: 0
      write-latency: 0
      write-transfer-time: 0
  memory-areas:
    - name: "code"
      type: "code"
      memory: "main"
      address-range:
        min: 0
        max: 0xFFFFFFFF
    - name: "data"
      type: "data"
      memory: "main"
      address-range:
        min: 0
        max: 0xFFFFFFFF


