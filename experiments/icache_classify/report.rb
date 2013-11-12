#!/usr/bin/env ruby
require 'yaml'
require 'csv'

#################### CONFIGURATION START ####################

# "trace" or "platin"
basesource = "platin"

# minimal instruction memory usage to include benchmark
min_imem, min_imem_no_rt = 1024, 0

# sort benchmarks by name (by instruction memory usage)
sort_proc = Proc.new { |target, columns, basecolumn|
  baseline = columns.find { |r| r['column'] == basecolumn }
  # baseline['imem_bytes']
  baseline['row']
}

# find cache size that delivers 95% of performance
threshold = 1.052


#################### CONFIGURATION END   ####################

def rel_cycle_diff(actual, baseline)
  (actual-baseline) / baseline.to_f * 100.0
end
def rel_cycles(actual, baseline)
  actual/baseline.to_f
end
def rel_cycles_str(actual, baseline, opts)
  width = opts[:width] || 9
  prec  = opts[:prec] || 2
  if opts[:diff_percent]
    sprintf("%#{width-1}.#{prec}f%%", rel_cycles_diff(actual, baseline))
  else
    sprintf("%#{width}.#{prec}f", rel_cycles(actual, baseline))
  end
end

# sources used
sources = [ basesource ]

# work directories
work_directories = ARGV
if work_directories.empty?
  work_directories = Dir.entries(File.dirname(__FILE__)).select { |s|
    s =~ /work.ic_(\d+)/
  }
end
work_directories.sort_by! { |s|
  s =~ /work.ic_(\d+)/
  - ($1.to_i)
}

# work names
worknames = work_directories.map { |dir|
  name = dir.sub(/^work./,'').chop
  [name, dir]
}

# basecolumn
basecolumn = worknames.first[0] + "/#{basesource}"

# rows
rows = worknames.map { |name,dir|
  file_data = YAML::load_stream(File.read("#{dir}/report.yml")).flatten
  file_data.map { |row|
    row['row']    = row['benchmark'] + "/" + row['analysis-entry']
    row['column'] = name + "/" + row['source']
    row
  }
}.flatten.group_by { |row| row["row"] }.select { |target, columns|
  baseline = columns.find { |r| r['column'] == basecolumn }
  if min_imem.to_i > 0 && baseline['imem_bytes'] < min_imem
    false
  elsif min_imem_no_rt.to_i > 0 && baseline['imem_bytes_no_rt'] < min_imem_no_rt
    false
  else
    true
  end
}.sort_by { |target, columns|
  sort_proc.call(target, columns, basecolumn)
}

# column names (including imem size)
column_names = worknames.map { |name,_|
  sources.map { |source|
    name+"/" + source
  }
}.flatten
column_names.each_with_index { |col_name,ix|
  $stderr.puts "[#{ix}] #{col_name}"
}

$stderr.puts "ROWS: #{rows.length}"

csv = CSV.generate(:col_sep => ";", :headers => true, :write_headers => true) { |csv|
  # header
  csv << [ "benchmark" ] + column_names.map { |cn| cn =~ /ic_(\d+)/ ; $1 } + [ "imem", "imem-no-rt", "min-size" ]
  rows.each { |target, columns|
    column_data = {}
    column_names.each { |k| column_data[k] = columns.find { |r| r['column'] == k  } }
    baseline = column_data[basecolumn]
    base_cycles = baseline['cycles']
    row = [ baseline['row'], base_cycles ]
    min_size = "ideal"
    column_data.each { |name,data|
      next if name == basecolumn
      unless data
        row.push("")
        next
      end
      rcyc = rel_cycles_str(data['cycles'],base_cycles,:width => 9, :diff_percent => false, :prec => 3)
      name =~ /ic_(\d+)/ ; size = $1
      min_size = size if rcyc.to_f <= threshold
      row.push(rcyc)
    }
    row.concat([ baseline['imem_bytes'], baseline['imem_bytes_no_rt'], min_size ])
    csv << row
  }
}
# print csv
File.open("report.csv","w") { |fh| fh.puts(csv) }
puts "Results is in report.csv"
system("R --slave --no-save < report.R")

