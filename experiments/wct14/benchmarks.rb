#
# Benchmark Selection for 'wcet' experiments
#
benchfilter_from_arg()
builds = %w{O0 O1} # {O0 O1 O1f O2}
configs = %w{notrace} #  {blockglobal blocklocal minimal notrace}
nozero = %w{papa_ debie1} # don't try -O0 with those

$benchmarks = wtc_benchmarks.map { |b|
  settings = standard_buildsettings.select { |s| builds.include?(s['name']) }

  # filter out problematic build configurations
  settings.select! { |s| not s['name'] == 'O0' } if nozero.any? { |nz|
    b['name'].start_with? nz }

  analyses = standard_configurations.select { |c| configs.include?(c['name']) }.collect_concat { |c| b['analyses'].map { |a| a.merge(c) { |k,a,b| a+"_"+b } } }
  b.merge('buildsettings' => settings, 'analyses' => analyses)
}.select { |b|
  ! $benchfilter || $benchfilter.call(b)
}

