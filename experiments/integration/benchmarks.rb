#
# Benchmark Selection for 'integration' experiments
#

# Build settings
build_settings = [ {'name' => 'O0', 'cflags' => '-O0'},
                   {'name' => 'O1', 'cflags' => '-O1'},
                   {'name' => 'O2', 'cflags' => '-O2'} ]

# Configuration
configurations = [ {'name' => 'blockglobal', 'recorders' => 'g:bil', 'flow-fact-selection' => 'all' },
                   {'name' => 'blocklocal',  'recorders' => 'g:cil,f:b', 'flow-fact-selection' => 'local' },
                   {'name' => 'minimal',     'recorders' => 'g:cil', 'flow-fact-selection' => 'minimal' } ]

# MRTC
# duff: (no loop bounds for -O0/minimal)
# fac: recursion (not properly supported by analyze-trace's local recorders)
benchmarks =
  %w{adpcm bs bsort100 cnt compress cover crc duff
     edn expint fdct fft1 fibcall fir insertsort janne_complex jfdctint lcdnum lms loop3
     ludcmp matmult minmax minver ns qsort-exam qurt select sqrt statemate}
current = {}
current['buildsettings'] = build_settings[2..2]
current['configurations'] = configurations[1..1]
$benchmarks = []
begin
  mrtc = current.dup
  mrtc['analysis_entry'] = 'main'
  mrtc['trace_entry']    = 'main'
  benchmarks.each do |name|
    c = mrtc.dup
    c['name'] = name
    c['path'] = "Malardalen/src/#{name}"
    $benchmarks.push(c)
  end
end
