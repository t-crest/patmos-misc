require 'ostruct'
require 'yaml'

$:.unshift File.dirname(__FILE__)
require 'gen_config.rb'

# map from burst size (in words) to transfer time
sc_tt = { 2=>9, 4=>10, 8=>13, 16=>21, 32=>38, 64 => 70 }


# TEST SETUP (1k caches)
#
config = OpenStruct.new
config.burst_size    = 32 # 8 words
config.request_delay = 0
config.transfer_time = sc_tt[config.burst_size / 4]
config.cache_size = 1024

configs = []
# cache 1: direct-mapped
configdm = config.dup
configdm.name = 'instruction-cache'
configdm.type = "set-associative"
configdm.associativity = 1
configdm.policy        = "fifo"
configdm.line_size     = config.burst_size
configs.push(configdm)

# cache 2: set-associative, fifo-8
config_fifo = config.dup
config_fifo.name = 'instruction-cache'
config_fifo.type = "set-associative"
config_fifo.associativity = 8
config_fifo.policy        = "fifo"
config_fifo.line_size     = config.burst_size
configs.push(config_fifo)

# cache 3: set-associative, lru-8
config_lru = config.dup
config_lru.name = 'instruction-cache'
config_lru.type = "set-associative"
config_lru.associativity = 8
config_lru.policy        = "lru"
config_lru.line_size     = config.burst_size
configs.push(config_lru)

keys, workdirs = [], []
configs.each { |config|
  key = get_key(config)
  config_file = "config.#{key}.pml"
  File.open(config_file, "w") { |fh|
    fh.write(YAML::dump(get_config(config)))
  }
  workdir = "work.#{key}"
  system("ruby run.rb #{config_file} work.#{key}")
  keys.push(key)
  workdirs.push(workdir)
}
puts("ruby report.rb #{workdirs.join(" ")}")
system("ruby report.rb #{workdirs.join(" ")}")
