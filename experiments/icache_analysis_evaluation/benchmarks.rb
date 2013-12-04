#
# Benchmark Selection for 'wcet' experiments
#
require 'set'

#################### CONFIGURATION START ####################

# 1k benchmarks (paper submission 1)
# benchmarks_tiny = %w{mrtc_crc mrtc_ndes mrtc_jfdctint mrtc_cnt mrtc_fdct}
# benchmarks_small = %w{mrtc_adpcm mrtc_edn mrtc_select}
# benchmarks_medium = %w{papa_fbw mrtc_qsort mrtc_ud}
# benchmarks_large = %w{mrtc_nsichneu}


# Classified Benchmarks
#######################

# need 256-1024 bytes instruction memory
benchmarks_micro=%w{papa_autopilot/link_fbw_send mrtc_ns papa_autopilot/receive_gps_data_task mrtc_insertsort mrtc_lcdnum
                    mrtc_bsort100 mrtc_fir mrtc_cover mrtc_minmax mrtc_expint mrtc_statemate mrtc_matmult}

# need less than 1k to achieve 95% performance
benchmarks_tiny = %w{papa_fbw/servo_transmit papa_autopilot/reporting_task mrtc_compress mrtc_adpcm}

# need 1k-2k to achieve 95% performance
benchmarks_small = %w{mrtc_fdct mrtc_cnt mrtc_jfdctint mrtc_end papa_autopilot/altitude_control_task mrtc_select mrtc_qsort}

# need 4k-8k to achieve 95% performance
benchmarks_medium = %w{papa_fbw/send_data_to_autopilot_task papa_fbw/check_failsafe_task papa_fbw/check_mega128_values_task mrtc_ud
                       papa_autopilot/stabilisation_task papa_fbw/test_ppm_task papa_autopilot/climb_control_task mrtc_minver
                       mrtc_qurt mrtc_ludcmp}

# need 16-32k to achieve 95% performance
benchmarks_large = %w{mrtc_fft1 mrtc_lms papa_autopilot/navigation_task mrtc_nsichneu}


benchmarks =  benchmarks_medium+benchmarks_large+benchmarks_small  # +benchmarks_tiny+
builds =  %w{O2}           # {O0 O1 O1f O2}
configs = %w{blockglobal} #  {blockglobal blocklocal minimal notrace}

#################### CONFIGURATION END   ####################


# selected targets
benchmark_targets = {}
benchmarks.map { |bn|
  if bn =~ /(.*)\/(.*)/
    (benchmark_targets[$1]||=Set.new).add($2)
  else
    benchmark_targets[bn] = :all
  end
}

# benchmark selection
$benchmarks = all_benchmarks.map { |b|
  settings = standard_buildsettings.select { |s| builds.include?(s['name']) }
  analyses = standard_configurations.select { |c| configs.include?(c['name']) }.collect_concat { |c| b['analyses'].map { |a| a.merge(c) { |k,a,b| a+"_"+b } } }
  b.merge('buildsettings' => settings, 'analyses' => analyses)
}.map { |benchmark|
  bname = benchmark['name']
  if benchmark_targets[bname] == :all
    benchmark
  elsif targets = benchmark_targets[bname]
    selected_analyses = benchmark['analyses'].select { |analysis|
      analysis['name'] =~ /^(.*?)_(?:[^_]+)$/
      targets.include?($1)
    }
    if selected_analyses.empty?
      nil
    else
      benchmark.merge('analyses' => selected_analyses)
    end
  else
    nil
  end
}.compact


