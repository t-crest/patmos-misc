require 'ostruct'
require 'yaml'

$:.unshift File.dirname(__FILE__)
require 'gen_config.rb'

# map from burst size (in words) to transfer time
sc_tt = { 2=>9, 4=>10, 8=>13, 16=>21, 32=>38, 64 => 70 }


# TEST SETUP
#
config = OpenStruct.new
config.associativity = 8
config.burst_size    = 32 # 8 words
config.line_size     = config.burst_size
config.request_delay = 0
config.transfer_time = sc_tt[config.burst_size / 4]
config.policy        = "lru"

cache_sizes = [256,512,1024,2048,4096,8192,8192*2,8192*4,1024*1024].reverse

keys, workdirs = [], []
cache_sizes.each { |cache_size|
  config.cache_size = cache_size
  key = get_ic_key(config)
  config_file = "config.#{key}.pml"
  File.open(config_file, "w") { |fh|
    fh.write(YAML::dump(get_ic_config(config)))
  }
  workdir = "work.#{key}"
  system("ruby run.rb #{config_file} work.#{key}")
  keys.push(key)
  workdirs.push(workdir)
}
system("ruby report.rb #{workdirs.join(" ")}")
