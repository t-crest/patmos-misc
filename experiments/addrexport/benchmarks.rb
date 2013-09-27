#
# Benchmark Selection for 'wcet' experiments
#
builds = %w{O1f} # O2} # {O0 O1 O1f O2}
configs = %w{minimal} # {blockglobal blocklocal minimal notrace}
$benchmarks = all_benchmarks.select { |b|
  if b['irreducible'] || b['recursive']
    false
  elsif b['expensive']
    false
  else
    true
  end
}.map { |b|
  settings = standard_buildsettings.select { |s| builds.include?(s['name']) }.map { |s| s.merge('cflags' => s['cflags']+" -Xllc --stats") }
  analyses = standard_configurations.select { |c| configs.include?(c['name']) }.collect_concat { |c| b['analyses'].map { |a| a.merge(c) { |k,a,b| a+"_"+b } } }
  b.merge('buildsettings' => settings, 'analyses' => analyses)
}.select { |b|
  ! $benchfilter || $benchfilter.call(b)
}


