#!/usr/bin/env ruby
#
# Experiments with compiler integration
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
require_configuration 'stackcache'


# configuration
config = OpenStruct.new
config.srcdir        = $benchsrc
config.builddir      = $builddir
config.workdir       = $workdir
config.benchmarks    = $benchmarks
config.build_log     = File.join(config.builddir, 'build.log')
config.report        = File.join(config.workdir, 'report.yml')
config.nice_pasim      = $nice_pasim
config.pml_config_file = $hw_config
config.do_update        = false
config.keep_trace_files = false

# currently there can be only one bounds file for all the benchmarks
config.platin_tool_config_opts = "--sca #{$lp_bounds_file}:#{$lp_solver}"

# customized benchmark script
class BenchTool < WcetTool
  def initialize(pml, options)
    super(pml,options)
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
config.options.runcheck     = false # true
config.options.trace_analysis = true
config.options.debug_type   = $debug
config.options.use_trace_facts = true
# config.options.compute_criticalities = true
config.options.disable_ait = true

# run benchmarks
build_and_run(config, BenchTool)

# summarize
keys = %w{benchmark build analysis source analysis-entry cycles cache-cycles}
print_csv(config.report, :keys => keys, :outfile => File.join(config.workdir,'report.csv'))
print_table(config.report, keys)


