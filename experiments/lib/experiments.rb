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

    # look for platin lib directory assuming installed or llvm/tools directory layout
    if libdir = File.join(File.dirname(File.dirname(path_to_platin)),"lib") and File.directory?(libdir)
      $:.unshift File.join(libdir,"platin")
    elsif libdir = File.join(File.dirname(path_to_platin),"lib") and File.directory?(libdir)
      $:.unshift libdir
    end
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

def benchfilter_from_arg
  if ARGV[0]
    $benchfilter = Proc.new { |b| b['name'].include?(ARGV[0]) }
  end
end

def require_configuration(directory)
  # configuration
  begin
    require 'configuration'
    require 'benchmarks'
  rescue LoadError => e
    die("Failed to load ../configuration.rb => create one from ../configuration.rb.dist")
  end
  begin
    benchmark_file = File.join(directory,'benchmarks')
    require benchmark_file
  rescue LoadError => e
    die("Failed to load 'benchmarks' => create a file 'benchmarks.rb' to select the benchmarks")
  end
end

def default_configuration
  config = OpenStruct.new
  config.srcdir        = $benchsrc
  config.builddir      = $builddir
  config.workdir       = $workdir
  config.benchmarks    = $benchmarks
  config.nice_pasim      = $nice_pasim
  config.pml_config_file = $hw_config
  config.nproc = $nproc
  config
end

def default_options(opts = {})
  options = OpenStruct.new
  options.objdump="patmos-llvm-objdump"
  options.pasim = "pasim"
  options.gzip  = "gzip"
  options.sweet = "sweet"
  options.alf_llc = "alf-llc"
  if nice_level = opts[:nice_pasim]
    options.pasim = "nice -n 0 #{options.pasim}"
    options.gzip  = "nice -n #{nice_level} gzip"
  end
  options.a3 = "a3patmos"
  options.ait_import_addresses = true
  options.wca_cache_regions = true
  options.wca_persistence_analysis = false
  options.wca_ideal_cache = false
  options.wca_minimal_cache = false
  options.text_sections=[".text"]
  options.stats = true
  options.debug_type   = $debug
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
    if ! @config.pml_config_file
      $stderr.puts "No config file configured. Exit."
      exit 1
    elsif ! File.exist?(@config.pml_config_file)
      $stderr.puts "Config file #{@config.pml_config_file} does not exist. Exit."
      exit 1
    elsif ! @config.options.disable_ait && ! which(@config.options.a3)
      $stderr.puts "ait enabaled, but #{@config.options.a3} not found. Exit"
      exit 1
    end
    # default parallelity is processor count
    nproc = @config.nproc.to_i # 0 if not an int
    nproc = Parallel.processor_count unless nproc > 0
    log("Running in #{nproc} process(es) w/ config: #{@config.pml_config_file}", :log => @build_log, :console => true)
    # forall benchmarks/buildsettings
    @config.benchmarks.each_with_index { |b,ix| b['index'] = ix }
    errors = 0
    collect_build_settings.each do |build_setting, benchmark_list|
      configure(build_setting)
      # FIXME parallel library has changed...
      #errors += Parallel.map(benchmark_list, :in_processes => nproc) { |benchmark|
      errors += benchmark_list.map { |benchmark|

        # benchmark options
        options = @config.options.dup
        options.build = build_setting['name']
        options.benchmark_name = benchmark['name']
        options.binary_file  = "#{build_setting['builddir']}/#{benchmark['path']}"
        options.bitcode_file = "#{options.binary_file}.bc"
        options.input        = [ "#{options.binary_file}.pml", @config.pml_config_file ]

        # build
        @build_log = File.join(build_setting['builddir'],"build.#{benchmark['name']}.log")
        log("##{benchmark['index']} Building Benchmark #{options.binary_file} [#{build_setting['name']}]", :log => @build_log, :console => true)
        run("cd #{File.dirname(options.binary_file)} && make #{File.basename(options.binary_file)}", :log => @build_log, :log_stderr => true)

        # For all analysis targets and all analysis configurations
        errors = 0
        benchmark['analyses'].each do |configuration|
          options.outdir   = File.join(@config.workdir, "#{benchmark['name']}.#{build_setting['name']}.#{configuration['name']}")
          options.output = File.join(options.outdir,"#{benchmark['name']}.pml")
          options.report=File.join(options.outdir, "report.yml")
          options.analysis_entry = configuration['analysis_entry']
          options.flow_fact_selection = configuration['flow-fact-selection']
          options.use_sca_graph = configuration['use_sca_graph'] || false

          # skip on update and existing report
          next if File.exists?(options.report) && @config.do_update
          FileUtils.remove_entry_secure(options.outdir) if File.exist?(options.outdir)
          FileUtils.mkdir_p(options.outdir)

          # trace analysis: skipped if no recorders and option disabled
          if ! configuration['recorders'] && ! options.trace_analysis
            options.trace_analysis = false
            options.use_trace_facts = false
            options.runcheck = false
          else
            options.trace_file = File.join(@config.tracedir || @config.workdir, "#{benchmark['name']}.#{build_setting['name']}.#{configuration['trace_entry']}.gz")
            options.trace_entry =  configuration['trace_entry']
            options.recorders = RecorderSpecification.parse(configuration['recorders'] || 'g:cil', 0)
            generate_trace(options, benchmark)
          end
          reportkeys = { 'benchmark' => benchmark['name'],
            'build' => build_setting['name'],
            'analysis' => configuration['name'] }
          options.report_append = reportkeys
          begin
            run_analysis(options, benchmark, build_setting, configuration)
          rescue MissingToolException => me
            raise me
          rescue Exception => e
            $stderr.puts "ERROR: Analysis #{reportkeys.inspect} failed: #{e}"
            puts e.backtrace
            errors += 1
          end
        end

        # save some disk space
        unless @config.keep_trace_files
          FileUtils.remove_entry_secure(options.trace_file) if options.trace_file && File.exist?(options.trace_file)
        end
        errors
      }.inject(0) { |a,b| a+b }
    end
    if errors > 0
      raise Exception.new("#{errors} Errors.")
    end

    # Join reports
    File.unlink(@config.report) if File.exist?(@config.report)
    @config.benchmarks.each do |benchmark|
      benchmark['buildsettings'].each do |build_setting|
        benchmark['analyses'].each do |configuration|
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
    raise Exception.new("No benchmarks specified") if build_settings.empty?
    build_settings
  end

  def configure(build_setting)
    # Configure
    build_setting['builddir'] ||= File.join(@config.builddir, build_setting['name'])
    FileUtils.mkdir_p(build_setting['builddir'])
    cflags = build_setting['cflags']
    ldflags = build_setting['ldflags']
    cmake_flags = ["-DCMAKE_TOOLCHAIN_FILE=#{File.join(@config.srcdir,"cmake","patmos-clang-toolchain.cmake")}",
                   "-DTACLE_BENCH=true",
                   "-DREQUIRES_PASIM=true",
                   "-DENABLE_CTORTURE=false",
                   "-DENABLE_TESTING=true",
                   "-DENABLE_EMULATOR=false",
                   "-DCMAKE_BUILD_TYPE=None",
                   "-DCMAKE_C_FLAGS='#{cflags}'",
                   "-DCMAKE_C_LINK_FLAGS='#{ldflags.chomp()}'",
                   "-DCONFIG_PML='#{File.expand_path(@config.pml_config_file)}'"
                  ]
    cmake_flags.push("-DBUILD_WCET_ANALYSIS=true") if @config.options.wcet_build
    cmake_flags = cmake_flags.join(" ")
    configure_log = File.join(build_setting['builddir'], 'configure.log')
    run("cd #{build_setting['builddir']} && cmake #{@config.srcdir} #{cmake_flags}", :log => configure_log, :console => true, :log_stderr => true)
  end

  def generate_trace(options, benchmark)
    build_msg_opts = { :log => @build_log, :console => true, :log_append => true }
    if File.exist?(options.trace_file) # && File.mtime(options.trace_file) <= File.mtime(options.binary_file)
      log("##{benchmark['index']} Using existing trace file #{options.trace_file}",
        build_msg_opts)
    else
      log("##{benchmark['index']} Generating Trace File #{options.trace_file}", build_msg_opts)
      run("#{options.pasim} `platin tool-config -t pasim -i #{@config.pml_config_file}` --flush-caches=#{options.analysis_entry} --debug 0 --debug-fmt trace -b #{options.binary_file} 2>&1 1>/dev/null | " +
          "#{options.gzip} > #{options.trace_file}", :log => @build_log, :log_stderr => true, :log_append => true)
    end
  end

  def run_analysis(options, benchmark, build_setting, configuration)
    analysis_log = File.join(options.outdir,"wcet.log")
    FileUtils.remove_entry_secure(analysis_log) if File.exist?(analysis_log)

    log_analysis_opts  = { :log => analysis_log, :console => true, :log_append => true }
    run_analysis_opts = { :log => analysis_log,
                          :log_stderr => true,
                          :log_append => true,
                          :config => configuration}
    if defined?(@analysis_tool.import_ff)
      flowfact_inputs = @analysis_tool.import_ff(benchmark, options)
      log("##{benchmark['index']} Adding User Flowfacts: #{flowfact_inputs}", log_analysis_opts)
      options.input += flowfact_inputs
    end
    key = "#{benchmark['name']}.#{build_setting['name']}.#{configuration['name']}"
    log("##{benchmark['index']} Analyzing Benchmark #{key}",
        log_analysis_opts)
    @analysis_tool.run(options, run_analysis_opts)
    log("##{benchmark['index']} Finished Analyzing Benchmark #{key}", log_analysis_opts)
  end
end


