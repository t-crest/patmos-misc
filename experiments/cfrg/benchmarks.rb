#
# Benchmark Selection for 'cfrg' experiments
#
builds = %w{O2} # O0 O1
configs = %w{blockglobal} # blocklocal minimal
$benchmarks = all_benchmarks.select { |b|
  if (b['irreducible'] || b['recursive'])
    false
  else
    true
  end
}.map { |b|
  settings = standard_buildsettings.select { |s| builds.include?(s['name']) }
  analyses = standard_configurations.select { |c| configs.include?(c['name']) }.collect_concat { |c| b['analyses'].map { |a| a.merge(c) { |k,a,b| a+"_"+b } } }
  b.merge('buildsettings' => settings, 'analyses' => analyses)
}
