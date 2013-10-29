# console helpers
require 'ostruct'

$start = Time.now


def log(msg,opts)
  prefix = opts[:prefix] || "LOG"
  str = "[#{prefix} #{Time.now - $start}] #{msg}"
  $stderr.puts(str) if opts[:console]
  File.open(opts[:log], opts[:log_append] ? "a" : "w") { |fh| fh.puts msg } if opts[:log]
end

# write to console stderr, ignoring redirections
def puts_stderr(msg)
  File.open("/dev/stderr","w") { |fh| fh.puts("[DEBUG] #{msg}") }
end

def die(msg)
  log(msg,:prefix => "ERR", :console => true)
  exit(1)
end

def redirect_output(options)
  previous_stdout, previous_stderr = $stdout, $stderr
  file_io = nil
  begin
    $stdout = file_io = File.open(options[:log], options[:log_append] ? "a" : "w") if options[:log]
    $stderr = file_io if options[:log_stderr]
    yield
  ensure
    file_io.close if file_io
    $stdout, $stderr = previous_stdout, previous_stderr
  end
end

def run(cmd,opts={})
  defaults = { :name => "shellcommand" }
  defaults.merge!(opts)
  log("Running #{opts[:name]}: #{cmd}", opts)
  system_opts = {}
  if opts[:log]
    system_opts[:out] = [ opts[:log], opts[:log_append] ? "a" : "w" ]
    system_opts[:err] = [ :child, :out ] if opts[:log_stderr]
  end
  system(cmd, system_opts)
  die("Command '#{cmd.inspect}' failed") unless $? == 0
end

# printing/export

def print_table(file, keys)
  entries = []
  data = File.open(file) { |fh| YAML::load_stream(fh) }.each { |entry| entries.concat(entry) }
  width = Hash[keys.map { |k| [ k, k.to_s.length ] }]
  entries.each { |entry|
    keys.each { |k| width[k] = [ width[k], entry[k].to_s.length ].max }
  }
  puts keys.map { |k| k.to_s.ljust(width[k]) } .join(" | ")
  entries.each { |entry|
    puts keys.map { |k| entry[k].to_s.ljust(width[k]) } .join(" | ")
  }
end

def print_csv(file, opts)
  sep = opts[:sep] || ';'
  entries = []
  data = File.open(file) { |fh| YAML::load_stream(fh) }.each { |entry| entries.concat(entry) }
  keys = opts[:keys] || entries.inject(Set.new) { |set,entry| entry.keys.each { |k| set.add(k) } }.to_a
  io = opts[:outfile] || "/dev/stdout"
  File.open(io, "w") do |fh|
    fh.puts opts[:keys].join(sep)
    entries.each { |entry|
      next unless ! opts[:filter] || opts[:filter].call(entry)
      fh.puts keys.map { |k| entry[k] }.join(sep)
    }
  end
end
