#!/bin/bash

function pretty {
  sort \
    | sed -e "s/_task//g" -e "s/autopilot/auto/g" \
          -e "s/gps_data/gps/g" \
          -e "s/mega128_values/mega128/g" \
          -e "s/data_to_auto/data/g" \
          -e "s/_/\\\\_/g" \
    | column -t
}

./singlepath.awk "results-dcideal/work/report.csv" | pretty
echo
./conventional.awk "results-full/work/report.csv" | pretty
echo
./conventional.awk "results-dcideal/work/report.csv" | pretty
