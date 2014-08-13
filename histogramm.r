library(ggplot2)

args <- commandArgs(TRUE)
print(args)
file = args[1]
outfile = args[2]

d =read.table(file, sep = "\t")


ggplot(d, aes(V2)) +
  geom_histogram(binwidth=0.05,colour="darkgreen", size=0.5, fill="white") +
  scale_x_log10(breaks=c(0.1,0.5,1,2,5,seq(from=10,to=60,by=20),100,1000),labels=c(0.1,0.5,1,2,5,seq(from=10,to=60,by=20),100,1000)) +
  xlab("fold_changes - Scale log 10")

ggsave(outfile)