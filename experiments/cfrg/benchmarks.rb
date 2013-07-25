#
# Benchmark Selection
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
# fac: recursion (not supported by SWEET, no properly supported by analyze-trace's local recorders)
# qsort-exam: SWEET fails on -O1 (no final states) [FIXME]
# select: SWEET fails on -O0 (no final states) [FIXME]
benchmarks =
  %w{adpcm bs bsort100 cnt compress cover crc duff fac
     edn expint fdct fft1 fibcall fir insertsort janne_complex jfdctint lcdnum lms loop3
     ludcmp matmult minmax minver ndes ns nsichneu qsort-exam qurt select sqrt statemate ud}
benchmarks = %w{bs}
current = {}
current['buildsettings'] = build_settings[0..2]

$benchmarks = []
begin
  mrtc = current.dup
  mrtc['analysis_entry'] = 'main'
  mrtc['trace_entry']    = 'main'
  benchmarks.each do |name|
    c = mrtc.dup
    c['name'] = name
    c['path'] = "Malardalen/src/#{name}"
    if name == 'duff'
      c['configurations'] = configurations[0..1]
    elsif name == 'fac'
      c['configurations'] = configurations[0..0]
    else
      c['configurations'] = configurations[0..2]
    end
    if name == 'qsort-exam' || name == 'fac' || name == 'select'
      c['disable-sweet'] = true
    end
    $benchmarks.push(c)
  end
end
