library('data.table')


# read data
df <- data.frame(read.csv("work/report.csv", header=TRUE, sep=";"))

# filter
sources = c("plaintf/aiT","llvmtf/aiT")
df <- subset(df, (source %in% sources))

# row,group,value
df$row   = factor(df$benchmark)
df$group = factor(df$source)
df$value = df$tracefacts

# drop unnecesary columns
df <- df[c("row","group","value")]

# compute mean
msrc <- data.table(df[c("group","value")])
dfmean <- msrc[,lapply(.SD,mean),by=list(group)]
dfmean$row = factor(replicate(nrow(dfmean),"<mean>"))
df <- rbind(df,dfmean)

# sort by row, group
df <- df[with(df, order(row, group)), ]
normgroup <- 1

# get table to plot
tab <- tapply(df$value, list(df$group, df$row), sum)

# plot
postscript('integration.ps')
colors=c('blue','red')
# layout(t(c(2,1)),widths=c(1,0.3))
# plot.new()
#legend("right", legend=c("llvm+aiT","aiT"), fill=colors)
bp <- barplot(tab, beside=T, main="Integrating LLVM's scalar evolution and aiT",
        col = colors,
#       xlab = "Benchmark",
        las = 2,
        legend=c("llvm+aiT","aiT"),
        ylab = "# External Flowfacts Needed")
# text(bp, 0, df$cycles, cex=1, pos=3)
dev.off()


