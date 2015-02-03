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
require_configuration 'debie-aiT'


# configuration
config = default_configuration()
config.build_log     = File.join(config.builddir, 'build.log')
config.report        = File.join(config.workdir, 'report.yml')
config.do_update        = false

# customized benchmark script
class BenchTool < WcetTool
  def initialize(pml, options)
    super(pml,options)
  end
  def BenchTool.run(options, run_opts)
    options.ff_template_file = run_opts[:config]['ais_template']
    redirect_output(run_opts) do
      pml = BenchTool.new(PMLDoc.from_files(options.input), options).run_in_outdir
      pml.dump_to_file(options.output) if options.output
    end
  end
end


# remove old files unless updating
FileUtils.remove_entry_secure(config.build_log) if File.exist?(config.build_log) && ! config.do_update

# options
config.options = default_options(:nice_pasim => config.nice_pasim)
#
config.options.enable_sweet = false
config.options.enable_wca   = false
config.options.disable_ait  = false
config.options.runcheck     = false
config.options.trace_analysis = false
config.options.use_trace_facts = false
#
config.options.wcet_build = true
config.options.verbose = true
# disable most AIS exports
config.options.ais_disable_export = AisExportTool.get_exports_list(except=['header','jumptables']).inspect

# run benchmarks
build_and_run(config, BenchTool)

# summarize
keys = %w{benchmark build analysis source analysis-entry cycles}
print_csv(config.report, :keys => keys, :outfile => File.join(config.workdir,'report.csv'))
print_table(config.report, keys)


