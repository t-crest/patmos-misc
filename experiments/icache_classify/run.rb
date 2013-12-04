#!/usr/bin/env ruby
#
# pasim cache experiments
#

# stdlib
require 'yaml'
require 'set'
require 'fileutils'

# load libraries
begin
  require 'lib/experiments'
rescue LoadError => e
  $:.unshift File.join(File.dirname(__FILE__),"..")
  require 'lib/experiments'
end
require_configuration File.basename(File.dirname(__FILE__))


# configuration
config = OpenStruct.new
config.pml_config_file = ARGV[0]
config.workdir       = ARGV[1] || die("Usage: run.rb config.pml workdir")
config.srcdir        = $benchsrc
config.builddir      = $builddir
config.benchmarks    = $benchmarks
config.build_log     = File.join(config.builddir, 'build.log')
config.report        = File.join(config.workdir, 'report.yml')
config.do_update        = true
config.keep_trace_files = true

# customized benchmark script
class BenchTool < WcetTool
  def initialize(pml, options)
    super(pml,options)
  end
  def report(additional_info)
    %w{trace platin}.each { |k|
      (additional_info[k]||={})['imem_bytes'] = $imem_bytes # bad bad hack
      (additional_info[k]||={})['imem_bytes_no_rt'] = $imem_bytes_no_rt # bad bad hack
    }
    super(additional_info)
  end
  def BenchTool.run(options, console_opts)
    redirect_output(console_opts) do
      pml = BenchTool.new(PMLDoc.from_files(options.input), options).run_in_outdir
      pml.dump_to_file(options.output) if options.output
    end
  end
end


# remove old files unless updating
FileUtils.remove_entry_secure(config.build_log) if File.exist?(config.build_log) && ! config.do_update

# options
config.options = default_options(:nice_pasim => config.nice_pasim)
config.options.enable_sweet = false
config.options.enable_wca   = true
config.options.disable_ait  = true
config.options.runcheck     = false # true
config.options.trace_analysis = true
config.options.debug_type   = $debug
config.options.use_trace_facts = true

# run benchmarks
build_and_run(config, BenchTool)

# summarize
keys = %w{benchmark build analysis source analysis-entry cycles imem_bytes imem_bytes_no_rt}
print_csv(config.report, :keys => keys, :outfile => File.join(config.workdir,'report.csv'))
print_table(config.report, keys)


