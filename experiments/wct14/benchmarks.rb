#
# Benchmark Selection for 'wcet' experiments
#
benchfilter_from_arg()
builds = %w{O0 O1} # {O0 O1 O1f O2}
configs = %w{notrace} #  {blockglobal blocklocal minimal notrace}
$benchmarks = wtc_benchmarks.map { |b|
  settings = standard_buildsettings.select { |s| builds.include?(s['name']) }
  analyses = standard_configurations.select { |c| configs.include?(c['name']) }.collect_concat { |c| b['analyses'].map { |a| a.merge(c) { |k,a,b| a+"_"+b } } }
  b.merge('buildsettings' => settings, 'analyses' => analyses)
}.select { |b|
  ! $benchfilter || $benchfilter.call(b)
}

