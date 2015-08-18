#!/bin/bash

function compare_benches() {
  base=$1
  pattern=$2
  namepattern=$3
  values=$4

  for bench in `ls work/$base | grep "wcet.txt"`; do
    name=${bench%-wcet.txt}
    suite=`echo "$name" | sed "s/-.*//"`
    benchname=`echo "$name" | sed "s/.*-//"`

    refcycles=`grep -A 1 "platin" work/$base/$bench | tail -n 1 | sed "s/ *cycles:  *\([0-9]*\)/\1/"`

    for i in $values; do
      config=${pattern//XX/$i}
      cname=${namepattern//XX/$i}

      cycles=`grep -A 1 "platin" work/$config/$bench | tail -n 1 | sed "s/ *cycles:  *\([0-9]*\)/\1/"`

      echo "\"$cname\", \"$suite\", \"$benchname\", $cycles, $refcycles"
    done

  done
}

#compare_benches "ideal" "pref_sf_XX_scc_XX_ideal" "XX/XX" "32 128 192 256 512 1024" > results/compare_ideal.csv
#compare_benches "ideal" "pref_sf_XX_scc_2048_ideal" "XX/2048" "128 192 256 512" >> results/compare_ideal.csv

# Compare to LRU
#
#compare_benches "nosplit_ic4k_lru4" "pref_sf_XX_scc_XX_mc4k_32" "XX/XX" "32 128 192 256 512 1024"  > results/compare_mc4k_32.csv
#compare_benches "nosplit_ic4k_lru4" "pref_sf_XX_scc_2048_mc4k_32" "XX/2048" "128 192 256 512"  >> results/compare_mc4k_32.csv
#
#compare_benches "nosplit_ic4k_lru4" "pref_sf_XX_scc_XX_mc4k_32_vb" "XX/XX" "32 128 192 256 512 1024"  > results/compare_mc4k_32_vb.csv
#compare_benches "nosplit_ic4k_lru4" "pref_sf_XX_scc_2048_mc4k_32_vb" "XX/2048" "128 192 256 512"  >> results/compare_mc4k_32_vb.csv
#
#compare_benches "nosplit_ic8k_lru4" "pref_sf_XX_scc_XX_mc8k_32" "XX/XX" "32 128 192 256 512 1024"  > results/compare_mc8k_32.csv
#compare_benches "nosplit_ic8k_lru4" "pref_sf_XX_scc_2048_mc8k_32" "XX/2048" "128 192 256 512"  >> results/compare_mc8k_32.csv
#
#compare_benches "nosplit_ic8k_lru4" "pref_sf_XX_scc_XX_mc8k_32_vb" "XX/XX" "32 128 192 256 512 1024"  > results/compare_mc8k_32_vb.csv
#compare_benches "nosplit_ic8k_lru4" "pref_sf_XX_scc_2048_mc8k_32_vb" "XX/2048" "128 192 256 512"  >> results/compare_mc8k_32_vb.csv
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
compare_benches "nosplit_ic4k_lru4" "pref_sf_XX_scc_XX_mc4k_32_vb" "XX/XX" "32 128 192 256 512 1024"  > results/wcet_mc4k_32_vb.csv
#compare_benches "nosplit_ic4k_lru4" "pref_sf_XX_scc_2048_mc4k_32_vb" "XX/2048" "32 128 192 256 512 1024"  >> results/wcet_mc4k_32_vb.csv


# Compare setups only

compare_benches "pref_sf_1024_scc_2048_mc4k_32_vb" "pref_sf_XX_scc_XX_mc4k_32_vb" "XX/XX" "32 128 192 256 512"      > results/wcet_mc_mc4k_32_vb.csv
#compare_benches "pref_sf_1024_scc_2048_mc4k_32_vb" "pref_sf_XX_scc_2048_mc4k_32_vb" "XX/2048" "32 128 192 256 512" >> results/wcet_mc_mc4k_32_vb.csv

#compare_benches "pref_sf_1024_scc_2048_mc8k_32_vb" "pref_sf_XX_scc_XX_mc8k_32_vb" "XX/XX" "32 128 192 256 512"      > results/wcet_mc_mc8k_32_vb.csv
#compare_benches "pref_sf_1024_scc_2048_mc8k_32_vb" "pref_sf_XX_scc_2048_mc8k_32_vb" "XX/2048" "32 128 192 256 512" >> results/wcet_mc_mc8k_32_vb.csv

compare_benches "pref_sf_1024_scc_1024_mc4k_64_vb" "pref_sf_XX_scc_XX_mc4k_64_vb" "XX/XX" "32 64 128 256 512"      > results/wcet_mc_mc4k_64_vb.csv
#compare_benches "pref_sf_1024_scc_1024_mc4k_64_vb" "pref_sf_XX_scc_2048_mc4k_64_vb" "XX/2048" "32 64 128 256 512" >> results/wcet_mc_mc4k_64_vb.csv



# Have a lot of different configurations, compare per benchmark

#compare_benches "nosplit_ic4k_lru4" "pref_sf_XX_scc_XX_mc4k_32" "XX, SCC XX" "32 128 192 256 512 1024"  > results/compare_benches.csv
#compare_benches "nosplit_ic4k_lru4" "pref_sf_XX_scc_2048_mc4k_32" "XX, SCC 2048" "128 256 512"  >> results/compare_benches.csv

#compare_benches "nosplit_ic4k_lru4" "pref_sf_XX_scc_XX_mc16k_32" "XX, SCC XX" "32 128 192 256 512 1024"  > results/compare_benches.csv
#compare_benches "nosplit_ic4k_lru4" "pref_sf_XX_scc_2048_mc16k_32" "XX, SCC 2048" "128 256 512"  >> results/compare_benches.csv

