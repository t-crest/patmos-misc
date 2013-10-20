def get_key_cache_name(config)
  return 'ic' if config.name != 'method-cache'
  return 'vs' if config.block_size * config.associativity < config.cache_size
  return 'fb' if config.max_subfunction_size && config.max_subfunction_size <= config.block_size
  return 'vb'
end

def get_key_cc(config, prefix="-")
  if config.name == 'method-cache'
    "#{prefix}#{config.max_subfunction_size.to_i}-#{config.preferred_subfunction_size.to_i}"
  else
    ""
  end
end

def get_key(config)
  sprintf("%s_%d-%d-%d-%s%s_%d-%d-%d",
          get_key_cache_name(config),
          config.cache_size, config.line_size || config.block_size, config.associativity, config.policy,
          get_key_cc(config,"-"),
          config.burst_size, config.request_delay, config.transfer_time)
end
def get_memories(config)
  [{ 'name' => "main",
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
end
def get_areas(icache)
  [{ 'name' => "code",
     'type' => "code",
     'memory' => "main",
     'cache' => icache,
     'address-range' => { 'min' => 0, 'max' => 0xFFFFFFFF }},
   { 'name' => "data",
     'type' => "data",
     'memory' => "local",
     'address-range' => { 'min' => 0, 'max' => 0xFFFFFFFF }}]
end

def get_pml(memories, caches, mem_areas)
  { 'format' => 'pml-0.1',
    'triple' => 'patmos-unknown-unknown-elf',
    'machine-configuration' =>
    { 'memories' => memories,
      'caches' => caches,
      'memory-areas' => mem_areas,
    }
  }
end

def get_config(config)
  memories = get_memories(config)
  cache = { 'name' => config.name,
    'block-size' => config.block_size || config.line_size,
    'associativity' => config.associativity,
    'size' => config.cache_size,
    'policy' => config.policy,
    'type' => config.type,
    'attributes' => [] }
  if config.max_subfunction_size
    cache['attributes'].push({'key' => 'max-subfunction-size', 'value' => config.max_subfunction_size })
  end
  if config.preferred_subfunction_size
    cache['attributes'].push({'key' => 'preferred-subfunction-size', 'value' => config.preferred_subfunction_size })
  end
  mem_areas = get_areas(cache['name'])
  get_pml(memories, [cache], mem_areas)
end
