def get_ic_key(config)
  sprintf("ic_%d-%d-%d-%s_%d-%d-%d",
          config.cache_size, config.line_size, config.associativity, config.policy,
          config.burst_size, config.request_delay, config.transfer_time)
end

def get_ic_config(config)
  memories = [{ 'name' => "main",
                'size' => 67108864,
                'transfer-size' => config.burst_size,
                'read-latency' => config.request_delay,
                'read-transfer-time' => config.transfer_time,
                'write-latency' => config.request_delay,
                'write-transfer-time' => config.transfer_time },
              { 'name' => "local",
                'size' => 67108864,
                'transfer-size' => 8,
                'read-latency' => 0,
                'read-transfer-time' => 0,
                'write-latency' => 0,
                'write-transfer-time' => 0 }]
  caches = [{ 'name' => "instruction-cache",
              'block-size' => config.line_size,
              'associativity' => config.associativity,
              'size' => config.cache_size,
              'policy' => config.policy,
              'type' => "set-associative" }]
  mem_areas = [{ 'name' => "code",
                 'type' => "code",
                 'memory' => "main",
                 'cache' => "instruction-cache",
                 'address-range' => { 'min' => 0, 'max' => 0xFFFFFFFF }},
               { 'name' => "data",
                 'type' => "data",
                 'memory' => "local",
                 'address-range' => { 'min' => 0, 'max' => 0xFFFFFFFF }}]
  pml_config = { 'format' => 'pml-0.1',
    'triple' => 'patmos-unknown-unknown-elf',
    'machine-configuration' =>
    { 'memories' => memories,
      'caches' => caches,
      'memory-areas' => mem_areas,
    }
  }
end
