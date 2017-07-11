# needs data.table library
# R $ install_packages('data.table')
library('data.table')


# read data
df <- data.frame(read.csv("work/report.csv", header=TRUE, sep=";"))

# for each benchmark
dir.create('ps')
for(b in levels(df$benchmark)) {

# filter on benchmark
dfb <- subset(df, benchmark == b)
dfb$benchmark = factor(dfb$benchmark)

# group/row
dfb$group = factor(dfb$build)
dfb$row   = factor(paste(dfb$analysis,dfb$source))

# drop unnecesary columns
dfb <- dfb[c("group","row","cycles")]

# sort by row, group
dfb <- dfb[with(dfb, order(group, row)), ]
normrow <- 1

# normalize data (via data.table)
dfb <- data.table(dfb)
dfb <- dfb[, cycles.norm := cycles/cycles[normrow], by="group"]
dfb <- as.data.frame(dfb)

# get table to plot
tab <- tapply(dfb$cycles.norm, list(dfb$row, dfb$group), sum)

# plot
postscript(paste('ps/',b,'.ps', sep=""))
colors=rainbow(min(7,nrow(tab)))
layout(t(c(2,1)),widths=c(1,0.6))
plot.new()
legend("right", legend=levels(dfb$row), fill=colors)
bp <- barplot(tab, beside=T, main="Benchmark Blot",
        col = colors,
        space = c(0,3),
        las = 2,
        ylim = c(max(0,min(dfb$cycles.norm)-0.05),min(2.0,max(dfb$cycles.norm)+0.05)),
        ylab = "Cycles")
dev.off()

}
