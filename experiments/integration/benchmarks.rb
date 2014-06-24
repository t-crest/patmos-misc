#
# Benchmark Selection for 'integration' experiments
#
builds = %w{O1}
configs = %w{minimal}
$benchmarks = all_benchmarks.select { |b|
  if b['irreducible'] || b['recursive']
    false
  else
    true
  end
}.map { |b|
  settings = standard_buildsettings.select { |s| builds.include?(s['name']) }
  analyses = standard_configurations.select { |c| configs.include?(c['name']) }.collect_concat { |c| b['analyses'].map { |a| a.merge(c) { |k,a,b| a+"_"+b } } }
  b.merge('buildsettings' => settings, 'analyses' => analyses)
}.select { |b|
  ! $benchfilter || $benchfilter.call(b)
}
