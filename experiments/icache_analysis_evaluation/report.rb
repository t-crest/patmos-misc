#!/usr/bin/env ruby
require 'yaml'

def rel_cycle_diff(actual, expected)
  (actual-expected) / expected.to_f * 100.0
end
def rel_cycles(actual, expected)
  actual/expected.to_f
end

sources = %w{trace platin pers/platin nocr/platin aiT minimal/platin ideal/platin}
workname = {}
ARGV.each { |argv|
  workname[argv] = argv.sub(/^work./,'').chop
}
basecolumn = workname[ARGV.first] + "/trace"

data = ARGV.map { |argv|
  file_data = YAML::load_stream(File.read("#{argv}/report.yml")).flatten
  file_data.map { |row|
    row['row'] = row['benchmark'] + "/" + row['analysis-entry']
    row['column'] = workname[argv] + "/" + row['source']
    row
  }
}.flatten
rows = data.group_by { |row| row["row"] }
column_names = workname.values.map { |workname|
  sources.map { |source|
    workname + "/" + source
  }
}.flatten

actual_column_names = []
processed_rows = rows.map { |target,columns|
  column_data = {}
  column_names.each { |k|
    d = columns.find { |r| r['column'] == k  }
    if d
      actual_column_names.push(k) unless actual_column_names.include?(k)
      column_data[k] = d
    end
  }
  column_data
}

puts "ROWS: #{rows.length}"
actual_column_names.each_with_index { |col_name,ix|
  puts "[#{ix}] #{col_name}"
}
printf("%-37s", "benchmark")
actual_column_names.each_with_index { |_,ix| printf(" %9s", "[#{ix}]") }
puts

processed_rows.each { |column_data|
  baseline = column_data[basecolumn]
  base_cycles = baseline['cycles']
  printf("%-38s %8d",baseline['row'], base_cycles)
  actual_column_names.each { |name|
    next if name == basecolumn
    data = column_data[name]
    unless data
      printf(" %9s","0")
      next
    end
    #printf(" %8.2f%%",rel_cycles_diff(data['cycles'],base_cycles))
    raise Exception.new("bad column: #{name}, #{data}") unless data['cycles'].to_i > 0
    printf("  %8.3f",rel_cycles(data['cycles'],base_cycles))
  }
  puts
}



