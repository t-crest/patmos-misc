#!/usr/bin/env ruby
#
# Experiments with compiler integration
#

require 'yaml'
require 'set'
require 'fileutils'

# parallel library
begin
  require 'parallel'
rescue LoadError => e
  $stderr.puts("FATAL parallel library not found => gem install parallel")
  exit 1
end

# Attempt to find platin lib
begin
  require 'platin'
rescue LoadError => e
  path_to_platin=`which platin 2>/dev/null`.strip
  if File.exist?(path_to_platin)
    libdir=File.join(File.dirname(File.dirname(path_to_platin)),"lib","platin")
    $:.unshift libdir
    require 'platin'
  else
    $stderr.puts("When trying to locate platin library - failed to locate platin executable #{path_to_platin}")
    raise e
  end
end

# Benchmark driver
include PML
require 'tools/transform'
require 'tools/wcet'

# benchmarking lib / benchmarks
begin
  require 'lib/console' # Console utils from ../lib
rescue LoadError => e
  $:.unshift File.join(File.dirname(__FILE__),"..")
  require 'lib/console'
end
require 'integration/benchmarks'

# configuration
begin
  require 'configuration'
rescue LoadError => e
  die("Failed to load ../configuration.rb => create one from ../configuration.rb.dist")
end


# configuration
srcdir     = $benchsrc
builddir   = $builddir
workdir    = $workdir
benchmarks = $benchmarks
report     = File.join(workdir, 'report.yml')
build_log  = File.join(builddir, 'build.log')
do_update  = File.exist?(report)

class BenchTool < WcetTool
  def initialize(pml, options)
    super(pml,options)
    @testcnt = 0
  end
  def add_timing_info(name, dict, tool = "aiT")
    origin = [name,tool].compact.join("/")
    entry = pml.timing.by_origin(origin)
    assert("No unique timing entry for origin #{origin}") { entry.length == 1 }
    entry = entry.first
    dict.each { |k,v|
      entry[k] = v
    }
  end
  def run_analysis
    options.flow_fact_selection = "all"
    prepare_pml

    ait_unknown_loops = Set.new
    ait_problem_name("plain")
    wcet_analysis([])
    add_timing_info("plain", "tracefacts" => 0, "flowfacts" => 0)

    File.readlines(options.ait_report_file).each do |line|
      # this is no useful metric for comparison (it does not determine whether WCET can be calculated)
      if line =~ /Loop '(.*?)': unknown loop bound/
        ait_unknown_loops.add($1)
      end
    end
    options.report_append['aiT-unknown-loops'] = ait_unknown_loops.size

    # run trace analysis
    trace_analysis
    add_timing_info("trace", {"tracefacts" => -1, "flowfacts" => 0}, nil)
    tracefacts = pml.flowfacts.filter(pml, "minimal", "trace", "machinecode")
    pml.flowfacts.add_copies(tracefacts,"tf")

    # wcet analysis using all trace facts
    ait_problem_name("tf")
    wcet_analysis(["tf"])
    add_timing_info("tf", "tracefacts" => tracefacts.length, "flowfacts" => tracefacts.length)
    unless pml.timing.by_origin("tf/aiT").first.cycles > 0
      die("Failed to calculate WCET for #{options.input}")
    end

    # find minimal set of trace facts needed to complete aiT analysis
    plain_tf = minimize_trace_facts([], tracefacts, "plain_tf")
    ait_problem_name("plaintf")
    wcet_analysis(["plain_tf"])
    add_timing_info("plaintf", "tracefacts" => plain_tf.length, "flowfacts" => plain_tf.length)

    # wcet analysis using llvm facts
    transform_down(["llvm.bc"],"llvm")
    llvm_ff = pml.flowfacts.by_origin("llvm")
    ait_problem_name("llvm")
    wcet_analysis(["llvm"])
    add_timing_info("llvm", "tracefacts" => 0, "flowfacts" => llvm_ff.length)

    # wcet analysus using minimal trace facts + llvm trace facts
    llvm_tf = minimize_trace_facts(["llvm"], tracefacts, "llvm_tf")
    ait_problem_name("llvmtf")
    wcet_analysis(["llvm","llvm_tf"])
    add_timing_info("llvmtf", "tracefacts" => llvm_tf.length, "flowfacts" => llvm_tf.length + llvm_ff.length)

    report(["tracefacts","flowfacts"])
    pml
  end

  def ait_problem_name(name)
    outdir = options.outdir
    mod = File.basename(options.binary_file, ".elf")
    basename = if name != "" then "#{mod}.#{name}" else mod end
    options.timing_output = name
    options.ais_file = File.join(outdir, "#{basename}.ais")
    options.apx_file = File.join(outdir, "#{basename}.apx")
    options.ait_result_file = File.join(outdir, "#{basename}.ait.xml")
    options.ait_report_file = File.join(outdir, "#{basename}.ait.txt")
  end

  def minimize_trace_facts(srcs, tracefacts, output)
    flowfacts = pml.flowfacts.by_origin(srcs)
    info("minimize trace facts: using #{flowfacts.size} static flow facts and #{tracefacts.size} trace facts")
    keep, queue = [], tracefacts.dup
    print_stats, options.stats = options.stats, false
    while ! queue.empty?
      test = queue.pop
      set = keep + queue
      pml.try do
        name = "#{@testcnt}.min"
        pml.flowfacts.add_copies(flowfacts+keep+queue,name)
        ait_problem_name(name)
        wcet_analysis([name])
        unless pml.timing.by_origin("#{name}/aiT").first.cycles > 0
          keep.push(test)
        end
        @testcnt += 1
      end
    end
    options.stats = print_stats
    pml.flowfacts.add_copies(keep, output)
    keep
  end

  def BenchTool.run(options, console_opts)
    redirect_output(console_opts) do
      pml = BenchTool.new(PMLDoc.from_files(options.input), options).run_in_outdir
      pml.dump_to_file(options.output) if options.output
    end
  end
end


# remove old files unless updating
File.unlink(report) if File.exist?(report) && ! do_update
FileUtils.remove_entry_secure(build_log) if File.exist?(build_log) && ! do_update
FileUtils.mkdir_p(builddir)

# options
options = OpenStruct.new
options.objdump="patmos-llvm-objdump"
options.pasim = "nice -n 0 pasim"
options.a3 = "a3patmos"
options.text_sections=[".text"]
options.stats = true
options.enable_sweet = false
options.disable_wca = true

# Collect build settings
build_settings = {}
benchmarks.each do |benchmark|
  benchmark['buildsettings'].each do |setting|
    (build_settings[setting]||=[]).push(benchmark)
  end
end

# forall benchmarks/buildsettings
run = 0
build_settings.each do |build_setting, benchmark_list|

  # Configure
  cmake_flags = ["-DCMAKE_TOOLCHAIN_FILE=#{File.join(srcdir,"cmake","patmos-clang-toolchain.cmake")}",
                 "-DREQUIRES_PASIM=true",
                 "-DENABLE_TESTING=true",
                 "-DCMAKE_C_FLAGS='#{build_setting['cflags']}'"].join(" ")
  build_msg_opts = { :log => build_log, :log_append => true, :console => true }
  build_cmd_opts = { :log => build_log, :log_stderr => true, :log_append => true }
  run("cd #{builddir} && cmake #{srcdir} #{cmake_flags}", build_cmd_opts)

  Parallel.each(benchmark_list) do |benchmark|

    binary = "#{builddir}/#{benchmark['path']}"

    log("##{run} Building Benchmark #{binary} [#{build_setting['name']}]", build_msg_opts)
    run("cd #{File.dirname(binary)} && make #{File.basename(binary)}", build_cmd_opts)

    options.trace_file = nil # run for first configuration

    # For all analysis targets
    benchmark['configurations'].each do |configuration|

      options.outdir = File.join(workdir, "#{benchmark['name']}.#{build_setting['name']}.#{configuration['name']}")
      options.report=File.join(options.outdir, "report.yml")
      next if File.exists?(options.report) && do_update
      FileUtils.remove_entry_secure(options.outdir) if File.exist?(options.outdir)
      FileUtils.mkdir_p(options.outdir)

      # First analysis of this binary
      if ! options.trace_file
        options.trace_file = File.join(options.outdir, "trace.gz")
        log("##{run} Generating Trace File #{options.trace_file}", build_msg_opts)
        run("pasim -q --debug 0 --debug-fmt trace -b #{binary} 2>&1 1>/dev/null | nice -n 19 gzip > #{options.trace_file}",
            build_cmd_opts)
      end

      reportkeys = { 'benchmark' => benchmark['name'],
                     'build' => build_setting['name'],
                     'analysis' => configuration['name'] }

      options.binary_file=binary
      options.bitcode_file="#{binary}.bc"
      options.input=["#{binary}.pml"]
      options.recorders = RecorderSpecification.parse(configuration['recorders'], 0)
      options.flow_fact_selection = configuration['flow-fact-selection']
      options.report_append=reportkeys
      options.analysis_entry = benchmark['analysis_entry']
      options.trace_entry = benchmark['trace_entry']

      analysis_log = File.join(options.outdir,"wcet.log")

      log_analysis_opts  = { :log => analysis_log, :console => true }
      log("##{run} Analyzing Benchmark #{benchmark['name']} / #{build_setting['name']} / #{configuration['name']}", log_analysis_opts)
      log_analysis_opts[:log_append] = true

      run_analysis_opts = { :log => analysis_log, :log_stderr => true, :log_append => true }
      BenchTool.run(options, run_analysis_opts)

      log("##{run} Finished Analyzing Benchmark #{benchmark['name']} / #{build_setting['name']} / #{configuration['name']}", log_analysis_opts)

      run+=1
    end
    FileUtils.remove_entry_secure(options.trace_file) if options.trace_file && File.exist?(options.trace_file) # save some disk space
  end
end

# Join reports
benchmarks.each do |benchmark|
  benchmark['buildsettings'].each do |build_setting|
    benchmark['configurations'].each do |configuration|
      bench_report = File.join(workdir, "#{benchmark['name']}.#{build_setting['name']}.#{configuration['name']}", "report.yml")
      File.open(report, "a") { |fh|
        fh.write(File.read(bench_report))
      }
    end
  end
end
      
# Summarize
keys = %w{benchmark build  aiT-unknown-loops analysis source analysis-entry cycles tracefacts flowfacts}
print_csv(report, :keys => keys, :outfile => File.join(workdir,'report.csv'))
puts
print_table(report, keys)

