#
# Benchmark Selection for 'scilp' experiments
#

# O1f build type but using -mpatmos-sca-root-occupied to spill more
buildsettings = standard_buildsettings << {'name' => 'O1fsp', 'cflags' => '-O1 -Xopt -disable-inlining -Xllc -mpatmos-sca-root-occupied', 'ldflags' => '' }

# SCA graph based analysis type
configurations = standard_configurations << standard_configurations.find { |c| c['name'] == 'minimal' }.merge({'name' => 'scagraph', 'use_sca_graph' => true})

builds = %w{O1fsp} # {O0 O1 O1f O2}
configs = %w{minimal} # scagraph}
$benchmarks = mrtc_benchmarks.select { |b|
  if b['irreducible'] || b['recursive']
    false
  elsif b['expensive']
    false
  else
    true
  end
}.map { |b|
  #settings = standard_buildsettings.select { |s| builds.include?(s['name']) }
  settings = buildsettings.select { |s| builds.include?(s['name']) }
  analyses = configurations.select { |c| configs.include?(c['name']) }.collect_concat { |c| b['analyses'].map { |a| a.merge(c) { |k,a,b| a+"_"+b } } }
  b.merge('buildsettings' => settings, 'analyses' => analyses)
}.select { |b|
  ! $benchfilter || $benchfilter.call(b)
}


