#
# Experiments with control-flow relation graphs
#
# ruby1.9.1 -I.. -I$HOME/patmos/local-install/lib/platin run.rb
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
require_configuration 'cfrg'

# configuration
config = default_configuration()
config.build_log     = File.join(config.builddir, 'build.log')
config.report        = File.join(config.workdir, 'report.yml')
config.do_update     = true
config.nice_pasim    = nil # positive integer
config.pml_config_file = File.join(File.dirname(__FILE__),"../configurations/config_local.pml")

# customized benchmark script
class BenchTool < WcetTool
  def initialize(pml, options)
    super(pml,options)
  end

  def run_analysis
    original_flow_fact_selection = options.flow_fact_selection
    prepare_pml

    trace_analysis if options.trace_analysis || options.use_trace_facts
    wcet_file_suffix("")
    wcet_analysis(["llvm","trace"])

    # roundtrip
    time("roundtrip transformation") do
      copy_compiler_rt("support")
      uptransform("uptransform")
      downtransform("support","uptransform","roundtrip")
    end
    options.flow_fact_selection = "all" # all transformed
    options.timing_output = "roundtrip"
    wcet_file_suffix('roundtrip')
    wcet_analysis(["roundtrip"])

    # sweet
    if options.enable_sweet
      options.sweet_ignore_volatiles = true
      options.timing_output = "sweet"
      options.sweet_generate_trace = true
      sweet_analysis
      relation_graph_validation()
      options.flow_fact_selection = "all" # no selection for SWEET constraints
      wcet_file_suffix('sweet')
      wcet_analysis(["sweet","support"])
    end
    pml.flowfacts.dump_stats(pml, DebugIO.new)
    report
    pml
  end
  def wcet_file_suffix(suffix)
    outdir = options.outdir
    mod = File.basename(options.binary_file, ".elf")
    basename = if suffix != "" then "#{mod}.#{suffix}" else mod end
    options.ais_file = File.join(outdir, "#{basename}.ais")
    options.apx_file = File.join(outdir, "#{basename}.apx")
    options.ait_report_prefix = File.join(outdir, "#{basename}.ait")
  end
  def relation_graph_validation
    RelationGraphValidationTool.run(pml,options)
  end
  def copy_compiler_rt(dst)
    opts = options.dup
    opts.transform_action = "copy"
    opts.flow_fact_srcs = ["llvm","trace"]
    opts.flow_fact_selection = "rt-support-#{opts.flow_fact_selection}"
    opts.flow_fact_output = dst
    TransformTool.run(pml, opts)
  end
  def uptransform(dst)
    opts = options.dup
    opts.transform_action = "up"
    opts.flow_fact_srcs = ["llvm","trace"]
    opts.flow_fact_output = dst
    TransformTool.run(pml,opts)
  end
  def downtransform(support,src,dst)
    opts = options.dup
    opts.flow_fact_srcs = [src]
    opts.flow_fact_selection = "all" # already selected
    opts.flow_fact_output = dst
    opts.transform_action = "down"
    TransformTool.run(pml,opts)
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
FileUtils.mkdir_p(config.builddir)

# options
config.options = default_options(:nice_pasim => config.nice_pasim)
config.options.enable_sweet = true # disable for CFRG roundtrip tests only
config.options.enable_wca   = true
config.options.runcheck     = false
config.options.trace_analysis = true
config.options.use_trace_facts = true

# run benchmarks
begin
  build_and_run(config, BenchTool)
rescue MissingToolException => me
  die("giving up (tool missing): #{me}")
end

# summarize
keys = %w{benchmark build analysis source analysis-entry cycles}
print_csv(config.report, :keys => keys, :outfile => File.join(config.workdir,'report.csv'))
print_table(config.report, keys)
