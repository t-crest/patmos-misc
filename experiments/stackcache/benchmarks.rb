#
# Benchmark Selection for 'scilp' experiments
#

# O1f build type but using -mpatmos-sca-root-occupied to spill more
#buildsettings = standard_buildsettings << {'name' => 'O1fsp', 'cflags' => '-O1 -Xopt -disable-inlining -Xllc -mpatmos-sca-root-occupied', 'ldflags' => '' } << {'name' => 'O0sp', 'cflags' => '-O0 -Xllc -mpatmos-sca-root-occupied', 'ldflags' => '' }
buildsettings = standard_buildsettings.map { |c| c['name'] == "O1f" ? {'name' => 'O1f', 'cflags' => '-O1 -Xopt -disable-inlining -Xllc -mpatmos-sca-root-occupied', 'ldflags' => '' } : c }


# SCA graph based analysis type
configurations = standard_configurations << standard_configurations.find { |c| c['name'] == 'notrace' }.merge({'name' => 'nt_scagraph', 'use_sca_graph' => true})

def map_build_settings(b,s)
  # the bounds file needs to configured per benchmark suite
  if b['suite'] == 'mrtc'
    s.update({'platin_tool_config_opts' =>"--sca #{File.expand_path('mrtc.lp')}:#{File.expand_path($lp_solver)}"})
  end
  s
end
def map_analyses(b,c)
  # recursion needs special trace and flow fact selection settings
  if c['name'].end_with? 'minimal' and b['recursive']
    c.update({'name' => c['name'].sub('minimal','ball'), 'flow-fact-selection' => 'all', 'recorders' => 'g:cilb'})
  end
  c
end

builds = %w{O1f} # {O0 O1 O1f O2}
configs = %w{notrace}
#configs = %w{notrace nt_scagraph}
$benchmarks = mrtc_benchmarks.select { |b|
  if b['irreducible'] || b['recursive']
    false
  elsif b['expensive']
    false
  else
    true
  end
}.map { |b|
  settings = buildsettings.select { |s| builds.include?(s['name']) }.map { |s| map_build_settings(b,s) }
  analyses = configurations.select { |c| configs.include?(c['name']) }.collect_concat { |c| b['analyses'].map { |a| a.merge(c) { |k,a,b| a+"_"+b } } }.map { |c| map_analyses(b,c) }
  b.merge('buildsettings' => settings, 'analyses' => analyses)
}.select { |b|
  ! $benchfilter || $benchfilter.call(b)
}
