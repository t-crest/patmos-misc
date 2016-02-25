#
# Benchmark Selection for 'wcet' experiments
#
benchfilter_from_arg()
builds = %w{nd} # {O0 O1 O1f O2 del nd mix}
configs = %w{notrace} #  {blockglobal blocklocal minimal notrace}
$benchmarks = mrtc_benchmarks.select { |b|
  if b['recursive']
    false
  elsif b['irreducible']
    true
  elsif b['expensive']
    true
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
