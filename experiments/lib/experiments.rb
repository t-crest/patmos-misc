#
# utilities for writing benchmarks
#

# libraries available as gems
require 'rubygems'
begin
  require 'parallel'
rescue LoadError => e
  $stderr.puts("FATAL parallel library not found => gem install parallel")
  exit 1
end

# Attempt to load platin library
begin
  require 'platin'
rescue LoadError => e
  path_to_platin=`which platin 2>/dev/null`.strip
  if File.exist?(path_to_platin)

    libdir = File.join(File.dirname(File.dirname(path_to_platin)),"lib")
    $:.unshift File.join(libdir,"platin")
    Gem.clear_paths
    ENV['GEM_PATH'] = File.join(libdir,"platin", "gems") + (ENV['GEM_PATH'] ? ":#{ENV['GEM_PATH']}" : "")

    require 'platin'
  else
    $stderr.puts("When trying to locate platin library - failed to locate platin executable (cmd: 'which platin')")
    raise e
  end
end

# Benchmark driver
include PML
require 'tools/transform'
require 'tools/wcet'

# local libraries
require 'lib/console'

def require_configuration(directory)
  # configuration
  begin
    require 'configuration'
  rescue LoadError => e
    die("Failed to load ../configuration.rb => create one from ../configuration.rb.dist")
  end
  begin
    benchmark_file = File.join(directory,'benchmarks')
    require benchmark_file
  rescue LoadError => e
    die("Failed to load 'benchmarks' => create a file 'benchmarks.rb' providing the benchmarks")
  end
end

def default_options(opts = {})
  options = OpenStruct.new
  options.objdump="patmos-llvm-objdump"
  options.pasim = "pasim"
  options.gzip  = "gzip"
  if nice_level = opts[:nice_pasim]
    options.pasim = "nice -n 0 #{options.pasim}"
    options.gzip  = "nice -n #{nice_level} gzip"
  end
  options.a3 = "a3patmos"
  options.text_sections=[".text"]
  options.stats = true
  options
end

def build_and_run(config, tool)
  b = BenchmarkTool.new(config, tool)
  b.run_all
end

class BenchmarkTool
  def initialize(config, analysis_tool)
    @config, @analysis_tool = config, analysis_tool
  end
  def run_all
    @build_msg_opts = { :log => @config.build_log, :log_append => true, :console => true }
    @build_cmd_opts = { :log => @config.build_log, :log_stderr => true, :log_append => true }
    # forall benchmarks/buildsettings
    @config.benchmarks.each_with_index { |b,ix| b['index'] = ix } 
    collect_build_settings.each do |build_setting, benchmark_list|
      configure(build_setting)
      Parallel.each(benchmark_list) do |benchmark|

        options = @config.options.dup
        options.binary_file  = "#{@config.builddir}/#{benchmark['path']}"
        options.bitcode_file = "#{options.binary_file}.bc"
        options.input        = ["#{options.binary_file}.pml"]
        options.trace_file   = nil # run for first configuration
        options.analysis_entry = benchmark['analysis_entry']
        options.trace_entry = benchmark['trace_entry']

        # build
        log("##{benchmark['index']} Building Benchmark #{options.binary_file} [#{build_setting['name']}]", @build_msg_opts)
        run("cd #{File.dirname(options.binary_file)} && make #{File.basename(options.binary_file)}", @build_cmd_opts)

        # For all analysis targets
        benchmark['configurations'].each do |configuration|

          options.outdir = File.join(@config.workdir, "#{benchmark['name']}.#{build_setting['name']}.#{configuration['name']}")
          options.report=File.join(options.outdir, "report.yml")

          # skip on update and existing report
          next if File.exists?(options.report) && @config.do_update
          FileUtils.remove_entry_secure(options.outdir) if File.exist?(options.outdir)
          FileUtils.mkdir_p(options.outdir)

          # trace analysis
          trace_analysis(options, benchmark) if ! options.trace_file  && options.trace_analysis

          reportkeys = { 'benchmark' => benchmark['name'],
            'build' => build_setting['name'],
            'analysis' => configuration['name'] }
          options.report_append = reportkeys
          options.recorders = RecorderSpecification.parse(configuration['recorders'], 0)
          options.flow_fact_selection = configuration['flow-fact-selection']

          run_analysis(options, benchmark, build_setting, configuration)
        end
        # save some disk space
        FileUtils.remove_entry_secure(options.trace_file) if options.trace_file && File.exist?(options.trace_file)
      end
    end

    # Join reports
    File.unlink(@config.report) if File.exist?(@config.report)
    @config.benchmarks.each do |benchmark|
      benchmark['buildsettings'].each do |build_setting|
        benchmark['configurations'].each do |configuration|
          bench_report = File.join(@config.workdir,
                                   "#{benchmark['name']}.#{build_setting['name']}.#{configuration['name']}",
                                   "report.yml")
          File.open(@config.report, "a") { |fh|
            fh.write(File.read(bench_report))
          }
        end
      end
    end      
  end
private
  def collect_build_settings
    build_settings = {}
    @config.benchmarks.each do |benchmark|
      benchmark['buildsettings'].each do |setting|
        (build_settings[setting]||=[]).push(benchmark)
      end
    end
    build_settings
  end
  def configure(build_setting)
    # Configure
    cmake_flags = ["-DCMAKE_TOOLCHAIN_FILE=#{File.join(@config.srcdir,"cmake","patmos-clang-toolchain.cmake")}",
                   "-DREQUIRES_PASIM=true",
                   "-DENABLE_TESTING=true",
                   "-DCMAKE_C_FLAGS='#{build_setting['cflags']}'"].join(" ")
    run("cd #{@config.builddir} && cmake #{@config.srcdir} #{cmake_flags}", @build_cmd_opts)
  end
  def trace_analysis(options, benchmark)
    options.trace_file = File.join(options.outdir, "trace.gz")
    log("##{benchmark['index']} Generating Trace File #{options.trace_file}",
        @build_msg_opts)
    run("#{options.pasim} -q --debug 0 --debug-fmt trace -b #{options.binary_file} 2>&1 1>/dev/null | " +
        "#{options.gzip} > #{options.trace_file}",
        @build_cmd_opts)
  end
  def run_analysis(options, benchmark, build_setting, configuration)
    analysis_log = File.join(options.outdir,"wcet.log")
    FileUtils.remove_entry_secure(analysis_log) if File.exist?(analysis_log)

    log_analysis_opts  = { :log => analysis_log, :console => true, :log_append => true }
    run_analysis_opts = { :log => analysis_log, :log_stderr => true, :log_append => true }
    key = "#{benchmark['name']}.#{build_setting['name']}.#{configuration['name']}"
    log("##{benchmark['index']} Analyzing Benchmark #{key}",
        log_analysis_opts)
    @analysis_tool.run(options, run_analysis_opts)
    log("##{benchmark['index']} Finished Analyzing Benchmark #{key}", log_analysis_opts)
  end
end


