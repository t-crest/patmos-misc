#!/usr/bin/python
import csv
import glob


def read_csv(csvname):
    stats = {}
    with open(csvname, 'rb') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='"', skipinitialspace=True)
        for row in reader:
            # ACET, WCET, dc hits, dc misses, dc total
            stats[row[0]] = [ float(row[1]), float(row[2]), float(row[3]), float(row[4]), float(row[3])+float(row[4]) ]
    return stats

def write_table(name, align, header, lines):
    f = open("results/"+name+".tex", "w")

    f.write("  \\begin{tabular}{"+align+"}\n")
    f.write("    \\hline\n")
    f.write("    "+header)
    f.write("    \\hline\n")
    f.writelines([ "    " + l for l in lines])
    f.write("    \\hline\n")
    f.write("  \\end{tabular}\n")
    f.close()

def get_speedups(stats, base, cols):
    s = []
    for i in cols:
        v = stats[i]/base[i] if base[i] > 0 else 1.0
        s.append(v)
    return s

def format_results(rs, emph = []):
    return [ "\\emph{"+s+"}" if i in emph else s for i, s in enumerate( [ "%.2f" % x for x in rs ] ) ]

stats_O2 = read_csv("work/default_O2.csv")
stats_O0 = read_csv("work/default_O0.csv")
stats_O1 = read_csv("work/default_O1.csv")
stats_O3 = read_csv("work/default_O3.csv")
stats_nolinkopts = read_csv("work/default_nolinkopts.csv")
stats_none = read_csv("work/default_none.csv")

stats_nostack = read_csv("work/default_nostackcache.csv")
stats_nostack4k = read_csv("work/dc4k_nostackcache.csv")

stats_singleissue = read_csv("work/default_singleissue.csv")
stats_nondelayed  = read_csv("work/default_nondelayed.csv")
stats_delayed  = read_csv("work/default_delayed.csv")

stats_noifcvt  = read_csv("work/default_noifcvt.csv")

#benches = sorted(stats_O2)
benches = [ b for b in sorted(stats_O2) if stats_O2[b][0] > 100 ]


# Build table for stack cache eval
header = "Benchmark & Sim & WCET & D\\$ Hits & D\\$ Misses & D\\$ Accesses \\\\ \n"
lines = []
for b in benches:
    ref = stats_O2[b]
    nostack = stats_nostack[b]
    nostack4k = stats_nostack4k[b]

    line = b.replace("_", "\\_").ljust(14)

    # No Stack cache (2k DC)
    # ACET, WCET, Hits, Misses, Total
    #line = line + " & " + " & ".join( [ "%.5f" % x for x in get_speedups(ref, nostack, range(5)) ] )

    # No Stack cache (4k DC)
    # ACET, WCET, Hits, Misses, Total
    line = line + " & " + " & ".join( format_results( get_speedups(ref, nostack4k, range(5)), [1] ) )

    lines.append(line + " \\\\ \n")

write_table("stackcache", "|l|rr|rrr|", header, lines)


# Build table for Scheduler
header = "Benchmark & Dual-Issue & Non-Delayed CFL & Mixed CFL \\\\ \n"
lines = []
sums=[0,0,0,0,0,0]
for b in benches:
    ref = stats_O2[b]
    single = stats_singleissue[b]
    delayed = stats_delayed[b]
    nondelayed = stats_nondelayed[b]

    line = b.replace("_", "\\_").ljust(14)

    # Dual-Issue speedup 
    line = line + " & " + " & ".join( format_results( get_speedups(ref, single, range(2)), [1] ) )
    
    # Non-Delayed branches
    line = line + " & " + " & ".join( format_results( get_speedups(nondelayed, delayed, range(2)), [1] ) )

    # Mixed branches
    line = line + " & " + " & ".join( format_results( get_speedups(ref, delayed, range(2)), [1] ) )

    lines.append(line + " \\\\ \n")

    sums[0] += (ref[0]/single[0])
    sums[1] += (ref[1]/single[1])
    sums[2] += (nondelayed[0]/delayed[0])
    sums[3] += (nondelayed[1]/delayed[1])
    sums[4] += (ref[0]/delayed[0])
    sums[5] += (ref[1]/delayed[1])
    

print [x/28.0 for x in sums]

write_table("scheduler", "|l|rr|rr|rr|", header, lines)

# Optimization levels
header = "Benchmarks & \\\\ \n"
lines = []

for b in benches:
    none = stats_none[b]
    O0 = stats_O0[b]
    O1 = stats_O1[b]
    O2 = stats_O2[b]
    nolink = stats_nolinkopts[b]

    line = b.replace("_", "\\_").ljust(14)

    #line = line + " & " + " & ".join( format_results( get_speedups(O0, O0, range(2)), [1] ) )
    line = line + " & " + " & ".join( format_results( get_speedups(O1, O0, range(2)), [1] ) )
    line = line + " & " + " & ".join( format_results( get_speedups(O2, O0, range(2)), [1] ) )
    line = line + " & " + " & ".join( format_results( get_speedups(nolink, none, range(2)), [1] ) )

    lines.append(line + "\\\\ \n")

write_table("optlevels", "|l|rr|rr|rr|rr|rr|", header, lines)

