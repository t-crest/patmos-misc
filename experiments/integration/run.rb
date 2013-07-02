#
# Experiments with compiler integration
#
# ruby1.9.1 -I../lib run.rb -I../lib -I$HOME/patmos-install/lib/platin run.rb
#
require 'yaml'
require 'fileutils'
require 'console'

# Benchmark driver
require 'platin'
include PML
require 'tools/transform'
require 'tools/wcet'

class BenchTool < WcetTool
  def initialize(pml, options)
    super(pml,options)
  end

  def run_analysis
    original_flow_fact_selection = options.flow_fact_selection
    prepare_pml

    plain_unknown = []
    ait_problem_name("plain")
    wcet_analysis([])
    File.readlines(options.ait_report_file).each do |line|
      if line =~ /Loop '(.*?)': unknown loop bound/
        (options.report_append['aiT-errors-plain'] ||= []).push("#{$1}")
      end
    end
    report
    pml
  end

  def ait_problem_name(name)
    outdir = options.outdir
    mod = File.basename(options.binary_file, ".elf")
    basename = if name != "" then "#{mod}.#{name}" else mod end
    options.ais_file = File.join(outdir, "#{basename}.ais")
    options.apx_file = File.join(outdir, "#{basename}.apx")
    options.ait_result_file = File.join(outdir, "#{basename}.ait.xml")
    options.ait_report_file = File.join(outdir, "#{basename}.ait.txt")
  end

  def BenchTool.run(options, console_opts)
    redirect_output(console_opts) do
      pml = BenchTool.new(PMLDoc.from_files(options.input), options).run_in_outdir
      pml.dump_to_file(options.output) if options.output
    end
  end
end


# local configuration
builddir = '/home/benedikt/patmos/benchmarks/build'

# configuration
require "#{File.dirname($0)}/benchmarks"
benchmarks = $benchmarks
do_update = File.exist?('report.yml')

# report
report = 'report.yml'
build_log = 'build.log'
File.unlink(report) if File.exist?(report) && ! do_update
FileUtils.remove_entry_secure(build_log) if File.exist?(build_log) && ! do_update

# options
options = OpenStruct.new
options.report=report
options.objdump="patmos-llvm-objdump"
options.pasim = "nice -n 0 pasim"
options.a3 = "a3patmos"
options.text_sections=[".text"]
options.stats = true
options.enable_sweet = false
options.disable_wca = true

# For all benchmarks
run = 0
benchmarks.each do |benchmark|
  binary = "#{builddir}/#{benchmark['path']}"
  benchmark['buildsettings'].each do |build_setting|

    cmake_flags = ["-DCMAKE_TOOLCHAIN_FILE=../cmake/patmos-clang-toolchain.cmake",
                   "-DREQUIRES_PASIM=true",
                   "-DENABLE_TESTING=true",
                   "-DCMAKE_C_FLAGS='#{build_setting['cflags']}'"].join(" ")

    options.trace_file = nil

    # For all analysis targets
    benchmark['configurations'].each do |configuration|

      options.outdir = File.join("work","#{benchmark['name']}.#{build_setting['name']}.#{configuration['name']}")
      next if File.exists?(options.outdir) && do_update
      FileUtils.remove_entry_secure(options.outdir) if File.exist?(options.outdir)
      FileUtils.mkdir_p(options.outdir)

      # First analysis of this binary
      if ! options.trace_file || ! File.exist?(binary)
        log("##{run} Building Benchmark #{binary} [#{build_setting['name']}]", :log => build_log, :log_append => true, :console => true)
        run("cd #{builddir} && cmake .. #{cmake_flags}", :log => build_log, :log_stderr => true, :log_append => true)
        run("cd #{File.dirname(binary)} && make #{File.basename(binary)}", :log => build_log, :log_stderr => true, :log_append => true)

        options.trace_file = File.join(options.outdir, "trace.gz")
        log("##{run} Generating Trace File #{options.trace_file}", :log => build_log, :log_append => true, :console => true)
        run("pasim -q --debug 0 --debug-fmt trace -b #{binary} 2>&1 1>/dev/null | nice -n 19 gzip > #{options.trace_file}")
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
      log("##{run} Analyzing Benchmark #{benchmark['name']} / #{build_setting['name']} / #{configuration['name']}", :log => analysis_log, :console => true)
      BenchTool.run(options, :log => analysis_log, :log_stderr => true)

      run+=1
    end
    FileUtils.remove_entry_secure(options.trace_file) if options.trace_file && File.exist?(options.trace_file) # save some disk space
  end
end

# Summarize
keys = %w{benchmark build analysis source analysis-entry cycles aiT-errors-plain}
print_csv(report, :keys => keys, :outfile => 'report.csv')
puts
print_table(report, keys)

