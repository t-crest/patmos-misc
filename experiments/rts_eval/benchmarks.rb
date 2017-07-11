#
# Benchmark Selection for 'wcet' experiments
#
benchfilter_from_arg()
builds = %w{O1f} # {O0 O1 O1f O2}
#configs = %w{blockglobal blocklocal minimal notrace}
configs = %w{blockglobal}




$benchmarks = papabench.select { |b|
  #! (b['irreducible'] || b['recursive'] || b['expensive'])
  ! (b['irreducible'] || b['recursive'])
}.map { |b|
  settings = standard_buildsettings.select { |s| builds.include?(s['name']) }
  # get single-path roots from analyses
  sp_roots = b['analyses'].map { |a| a['analysis_entry'] }
  # duplicate settings for -sp variant
  settings_sp = settings.map { |s|
    sd = s.dup
    sd['name'] += "-sp"
    sd['cflags'] += " -mpatmos-singlepath=\"#{sp_roots.join(",")}\""
    sd
  }
  analyses = standard_configurations.select { |c|
    configs.include?(c['name'])
  }.collect_concat { |c|
    b['analyses'].map { |a| a.merge(c) { |k,a,b| a+"_"+b } }
  }
  b.merge('buildsettings' => settings + settings_sp, 'analyses' => analyses)
}.select { |b|
  ! $benchfilter || $benchfilter.call(b)
}




