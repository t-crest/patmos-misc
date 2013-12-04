#!/usr/bin/env ruby

require 'yaml'
require 'csv'

#################### CONFIGURATION START ####################

sources = %w{trace platin pers/platin nocr/platin aiT minimal/platin ideal/platin}
basesource = "trace"

# define column filter
column_filter = Proc.new { |col_name|
  if col_name =~ /fifo/
    col_name =~ /trace/
  else
    true
  end
}

# define order
benchmarks_small = %w{mrtc_fdct mrtc_cnt mrtc_jfdctint mrtc_end papa_autopilot/altitude_control_task mrtc_select mrtc_qsort}
benchmarks_medium = %w{papa_fbw/send_data_to_autopilot_task papa_fbw/check_failsafe_task papa_fbw/check_mega128_values_task mrtc_ud
                       papa_autopilot/stabilisation_task papa_fbw/test_ppm_task papa_autopilot/climb_control_task mrtc_minver
                       mrtc_qurt mrtc_ludcmp}
benchmarks_large = %w{mrtc_fft1 mrtc_lms papa_autopilot/navigation_task mrtc_nsichneu}
order_map = Hash.new(0)
[[benchmarks_small,1],[benchmarks_medium,2],[benchmarks_large,3]].each { |benchgroup, order|
  benchgroup.each { |benchname|
    benchname += "/main" if benchname !~ /\//
    order_map[benchname] = order
  }
}
benchmark_order = Proc.new { |name|
  order_map[name]
}

#################### CONFIGURATION END   ####################

def rel_cycle_diff(actual, expected)
  (actual-expected) / expected.to_f * 100.0
end
def rel_cycles(actual, expected)
  actual/expected.to_f
end

# work directories
work_directories = ARGV
if work_directories.empty?
  work_directories = Dir.entries(File.dirname(__FILE__)).select { |s|
    s =~ /work.ic_(\d+)/
  }
end

puts "work directories: #{work_directories}"
# work names
workname = {}
work_directories.each { |dir|
  workname[dir] = dir.sub(/^work./,'').chop
}
basecolumn = workname[work_directories.first] + "/" + basesource

# data preprocessing
data = work_directories.map { |argv|
  file_data = YAML::load_stream(File.read("#{argv}/report.yml")).flatten
  file_data.map { |row|
    row['row'] = row['benchmark'] + "/" + row['analysis-entry']
    row['column'] = workname[argv] + "/" + row['source']
    row
  }
}.flatten
rows = data.group_by { |row| row["row"] }.sort_by { |target,_| benchmark_order.call(target) }
column_names = workname.values.map { |workname|
  sources.map { |source|
    workname + "/" + source
  }
}.flatten

# column names
actual_column_names = []
processed_rows = rows.map { |target,columns|
  column_data = {}
  column_names.each { |k|
    d = columns.find { |r| r['column'] == k  }
    if d && column_filter.call(k)
      actual_column_names.push(k) unless actual_column_names.include?(k)
      column_data[k] = d
    end
  }
  column_data
}

$stderr.puts "ROWS: #{rows.length}"

# CSV generation
csv = CSV.generate(:col_sep => ";", :headers => true, :write_headers => true) { |csv|

  # header
  # column names: e.g. ic_4096-32-8-lru_32-0-1/ideal/platin -> lru-8/ideal
  csv << [ "benchmark" ] + actual_column_names.map { |cn| cn =~ /^ic_(\d+)-(\d+)-(\d+)-(\w+)_(\d+)-(\d+)-(\d+)\/(\w+)/; $4 + "-" + $3 + "/" + $8 }

  # data
  processed_rows.each { |column_data|
    baseline = column_data[basecolumn]
    base_cycles = baseline['cycles']
    row = [ baseline['row'], base_cycles ]
    actual_column_names.each { |name|
      next if name == basecolumn
      data = column_data[name]
      unless data
        row.push("")
        next
      end
      raise Exception.new("bad column: #{name}, #{data}") unless data['cycles'].to_i > 0
      row.push(sprintf("  %8.3f",rel_cycles(data['cycles'],base_cycles)))
    }
    csv << row
  }
}

File.open("report.csv","w") { |fh| fh.puts(csv) }
puts "Results is in report.csv"

# R evaluation
system("R --slave --no-save < report.R")




