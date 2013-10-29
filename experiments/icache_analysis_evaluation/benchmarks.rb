#
# Benchmark Selection for 'wcet' experiments
#

benchmarks_tiny = %w{mrtc_crc mrtc_ndes mrtc_jfdctint mrtc_cnt mrtc_fdct}
benchmarks_small = %w{mrtc_adpcm mrtc_edn mrtc_select}
benchmarks_medium = %w{papa_fbw mrtc_qsort mrtc_ud}
benchmarks_large = %w{mrtc_nsichneu}

builds = %w{O2} # {O0 O1 O1f O2}
configs = %w{blockglobal} #  {blockglobal blocklocal minimal notrace}
$benchmarks = (mrtc_benchmarks + papabench).select { |b|
  if b['irreducible'] || b['recursive']
    false
  elsif b['expensive']
    true
  else
    [benchmarks_tiny,benchmarks_small,benchmarks_medium,benchmarks_large].any? { |bset| bset.include?(b['name']) }
  end
}.map { |b|
  settings = standard_buildsettings.select { |s| builds.include?(s['name']) }
  analyses = standard_configurations.select { |c| configs.include?(c['name']) }.collect_concat { |c| b['analyses'].map { |a| a.merge(c) { |k,a,b| a+"_"+b } } }
  b.merge('buildsettings' => settings, 'analyses' => analyses)
}.select { |b|
  ! $benchfilter || $benchfilter.call(b)
}


