#
# Benchmark Selection for 'integration' experiments
#

# Build settings
build_settings = [ {'name' => 'O0', 'cflags' => '-O0'},
                   {'name' => 'O1', 'cflags' => '-O1'},
                   {'name' => 'O2', 'cflags' => '-O2'} ]

# Configuration
configurations = [ {'name' => 'blockglobal', 'recorders' => 'g:bil', 'flow-fact-selection' => 'all' },
                   {'name' => 'blocklocal',  'recorders' => 'g:cil,f:b', 'flow-fact-selection' => 'all' },
                   {'name' => 'minimal',     'recorders' => 'g:cil', 'flow-fact-selection' => 'all' } ]

#
# MRTC
#
# disabled = %w{duff fac}
# duff: irreducible loop (no loop bounds for -O0/minimal)
# fac: recursion (not properly supported by analyze-trace's local recorders)
benchmarks = %w{adpcm bs bsort100 cnt compress cover crc
     edn expint fdct fft1 fibcall fir insertsort janne_complex jfdctint lcdnum lms loop3
     ludcmp matmult minmax minver ndes ns nsichneu qsort-exam qurt select sqrt statemate ud}
current = {}

# Compile with -O1
current['buildsettings'] = build_settings[1..1]

# Analyze using the following trace facts: loop bounds, infeasible blocks, calltargets [disabled: function-local block frequencies]
current['configurations'] = configurations[2..2]

# generate list of benchmarks

$benchmarks = []
begin
  # MRTC
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
