#!/usr/bin/python
import csv

def calc_stats(csv):
    functions = 0
    bbs = 0
    regions = 0
    maxregions = 0
    maxtime = 0
    maxbbs = 0
    totaltime = 0
    totalregionsize = 0
    maxregionsize = 0
    totalorigsize = 0
    maxincrease = 0
    origsize = 0

    names={}
    skip = False

    rcount = 0
    rsumsize = 0

    for row in csv:
        if row[2] == 'fun':
            if row[1] in names:
                skip = True
            else:
                if row[1] != "main":
                    names[row[1]] = row[0]
                skip = False

            increase = rsumsize - origsize
            if increase > maxincrease:
                maxincrease = increase

            functions = functions + 1
            bbs = bbs + int(row[3])
            time = float(row[5])
            if time > maxtime:
                maxtime = time
            totaltime = totaltime + time
            origsize = int(row[4])
            totalorigsize = totalorigsize + origsize
            
            if rcount > maxregions:
                maxregions = rcount
            rcount = 0
            rsumsize = 0
        else:
            regions = regions + 1
            rcount = rcount + 1
            rbb = int(row[3])
            if rbb > maxbbs:
                maxbbs = rbb
            rsize = int(row[5])
            rsumsize = rsumsize + rsize
            totalregionsize = totalregionsize + rsize
            if rsize > maxregionsize:
                maxregionsize = rsize

    if rcount > maxregions:
        maxregions = rcount
    increase = rsumsize - origsize
    if increase > maxincrease:
        maxincrease = increase

    stats = {"functions": functions, "bbs": bbs, "regions": regions, "maxregions": maxregions, "maxbbs": maxbbs, 
             "totalregionsize": totalregionsize, "maxregionsize": maxregionsize, 
             "totalorigsize": totalorigsize, "maxincrease": maxincrease,
             "maxtime": maxtime, "totaltime": totaltime}

    return stats


sizes = [32, 64, 128, 256, 512, 1024]

stats = {}
for i in sizes:
    csvname = "work/splitter_pref_sf_%d_scc_%d.csv" % (i, i)
    with open(csvname, 'rb') as csvfile:
        print " -- Processing ", csvname
        reader = csv.reader(csvfile, delimiter=',', quotechar='"', skipinitialspace=True)
        stats[i] = calc_stats(reader)


print

print "Region grow limit & ", " & ".join(map(str, sizes)), "\\\\"
print "\\hline"
print "Functions splitted & ", " & ".join( (str(stats[i]["functions"]) for i in sizes) ), "\\\\"
print "Regions emitted & ", " & ".join( (str(stats[i]["regions"]) for i in sizes) ), "\\\\"

print "Regions per function (avg/max) & ", " & ".join( ("%4.1f / %d" % (stats[i]["regions"] / stats[i]["functions"], stats[i]["maxregions"]) for i in sizes) ), "\\\\"
print "Basic blocks per region (avg/max) & ", " & ".join( ("%4.1f / %d" % (float(stats[i]["bbs"]) / stats[i]["regions"], stats[i]["maxbbs"]) for i in sizes) ), "\\\\"
print "Region size (avg/max) (bytes) & ", " & ".join( ("%4.1f / %d" % (float(stats[i]["totalregionsize"]) / stats[i]["regions"], stats[i]["maxregionsize"]) for i in sizes) ), "\\\\"
print "Code size increase (avg/max) (bytes) & ", " & ".join( ("%4.1f / %d" % (float(stats[i]["totalregionsize"] - stats[i]["totalorigsize"])/stats[i]["regions"], stats[i]["maxincrease"]) for i in sizes) ), "\\\\"
print "Total code size increase (kB) & ", " & ".join( ("%4.1f" % (float(stats[i]["totalregionsize"] - stats[i]["totalorigsize"])/1024) for i in sizes) ), "\\\\"

#print "Runtime per function (avg/max) (ms) & ", " & ".join( (str(stats[i]["totaltime"] / stats[i]["functions"]) + "/" + str(stats[i]["maxtime"]) for i in sizes) ), "\\\\"
print "Max runtime per function (ms) & ", " & ".join( (("%4.1f" % stats[i]["maxtime"]) for i in sizes) ), "\\\\"
print "Total runtime (ms) & ", " & ".join( (("%1.1f" % stats[i]["totaltime"]) for i in sizes) ), "\\\\"
