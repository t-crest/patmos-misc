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
require_configuration 'addrexport'
require 'tools/late-bypass'

# configuration
config = OpenStruct.new
config.srcdir        = $benchsrc
config.builddir      = $builddir
config.workdir       = $workdir
config.benchmarks    = $benchmarks
config.report        = File.join(config.workdir, 'report.yml')
config.do_update     = false
config.pml_config_file = File.join(File.dirname(__FILE__),'config.pml')
#config.keep_trace_files = true
config.nice_pasim    = nil # 10 # positive integer
config.options = default_options(:nice_pasim => config.nice_pasim)
config.options.enable_sweet = false
config.options.debug_type = :cache
config.options.enable_wca   = false
config.options.trace_analysis =  true
config.options.use_trace_facts = true
config.options.recorder
# config.options.compute_criticalities = true

# customized benchmark script
class BenchTool < WcetTool
  def initialize(pml, options)
    super(pml,options)
  end

  def ait_problem_name(name)
    outdir = options.outdir
    mod = File.basename(options.binary_file, ".elf")
    basename = if name != "" then "#{mod}.#{name}" else mod end
    options.timing_output = name
    options.ais_file = File.join(outdir, "#{basename}.ais")
    options.apx_file = File.join(outdir, "#{basename}.apx")
    options.ait_report_prefix = File.join(outdir, "#{basename}.ait")
  end



  def wcet_analysis(srcs)
    # run analysis without address export
    pml.with_temporary_sections([:valuefacts]) do
      options.ais_disable_export = Set['mem-addresses']
      ait_problem_name("no-addresses")
      wcet_analysis_ait(srcs)
      wcet_analysis_platin(srcs)
      extract_stats("no-addresses")
    end

    # run analysis with address export, bypass
    begin
      pml.with_temporary_sections([:valuefacts]) do
        options.ais_disable_export = Set.new
        ait_problem_name("with-addresses")
        wcet_analysis_ait(srcs)
        wcet_analysis_platin(srcs)
        extract_stats("with-addresses")

        options.range_treshold = Math.log2(pml.arch.data_cache.size)
        options.backup   = true
        LateBypassTool.run(pml, options)
      end

      # run analysis on final executable (with bypassed loads)
      ait_problem_name("with-bypass")
      wcet_analysis_ait(srcs)
      wcet_analysis_platin(srcs)
      extract_stats("with-bypass")
    ensure
      if File.exist?(options.binary_file + ".bak")
        FileUtils.mv(options.binary_file, options.binary_file + ".bypass")
        FileUtils.mv(options.binary_file+".bak", options.binary_file)
      end
    end
  end
  def extract_stats(problem_name)
    # extract statistics
    info = {}
    # hack to simplify reading results
    additional_report_info['trace'] = { 'reads-stats' => "total/exact/nearly/imprecise/unknown" }
    %w{reads writes}.each { |access|
      ait_line = `grep 'total #{access}' #{options.ait_report_prefix}.txt`
      ait_line =~ /(\d+) total #{access}\s+:\s+(\d+) exact.*?,\s+(\d+) nearly exact.*?,\s+(\d+) imprecise.*?,\s+(\d+) unknown/
      info[access+"-stats"] = "#{$1}/#{$2}/#{$3}/#{$4}/#{$5}"
    }
    additional_report_info[problem_name+"/aiT"] = info
  end
  def BenchTool.run(options, console_opts)
    redirect_output(console_opts) do
      pml = BenchTool.new(PMLDoc.from_files(options.input), options).run_in_outdir
      pml.dump_to_file(options.output) if options.output
    end
  end
end

# run benchmarks
build_and_run(config, BenchTool)

# summarize
keys = %w{benchmark build analysis source analysis-entry cycles reads-stats writes-stats}
print_csv(config.report, :keys => keys, :outfile => File.join(config.workdir,'report.csv'))
print_table(config.report, keys)


