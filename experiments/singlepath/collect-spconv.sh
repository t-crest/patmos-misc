#!/bin/bash


# $1 Benchmark
# $2 ET
# $3 #Pred
# $4 #Insrt
# $5 #BrRm
# $6 #SpillBits
# $7 #NoSpill

# noopt
# bcopy
# nospill
# allopt


# stats
echo ---
echo SP stats
echo ---
cat results.noopt.txt | awk '
  BEGIN { OFMT="%.2f" }
  {
    print $1, $3, $5, $4, $2
  }
' | column -t


# bcopy opt
echo ---
echo bcopy optimisation:
echo ---
paste results.{noopt,bcopy}.txt | awk '
  BEGIN { OFMT="%.2f" }
  {
    print $1,
        $9, (int($2) != 0) ? 100*($2 -  $9)/$2 : "N/A",
       $11, (int($4) != 0) ? 100*($4 - $11)/$4 : "N/A";
  }
' | column -t

# spill opt
echo ---
echo no spill optimisation:
echo ---
paste results.{noopt,nospill}.txt | awk '
  BEGIN { OFMT="%.2f" }
  {
    print $1, $14,
        $9, (int($2) != 0) ? 100*($2 -  $9)/$2 : "N/A",
       $11, (int($4) != 0) ? 100*($4 - $11)/$4 : "N/A";
  }
' | column -t

# all opts
echo ---
echo all optimisations:
echo ---
paste results.{noopt,allopt}.txt | awk '
  BEGIN { OFMT="%.2f" }
  {
    print $1,
        $9, (int($2) != 0) ? 100*($2 -  $9)/$2 : "N/A",
       $11, (int($4) != 0) ? 100*($4 - $11)/$4 : "N/A";
  }
' | column -t
