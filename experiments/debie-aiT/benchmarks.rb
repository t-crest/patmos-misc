#
# debie1 benchmark settings for the use with AIS templates
#
benchfilter_from_arg()
# the loop bounds expressed in AIS rely on inlining to happen, thus O2 is used
builds = %w{O2} # {O1 O1f O2}
configs = %w{notrace}
$benchmarks = debie1.select { |b|
  true
}.map { |b|
  settings = standard_buildsettings.select { |s| builds.include?(s['name']) }
  analyses = []
  b['ais_templates'].each { |a,e|
    analyses << {'name' => File.basename(a).split('.')[0],
                 'ais_template' => a,
                 'analysis_entry' => e }
  }
  b.merge('buildsettings' => settings, 'analyses' => analyses)
}.select { |b|
  ! $benchfilter || $benchfilter.call(b)
}

$benchmarks.each {|b| puts b['analyses'] }
