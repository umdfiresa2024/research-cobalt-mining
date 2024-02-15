library("haven")

dir("Berman/Data/")
df<-read_dta("Berman/Data/BCRT_baseline.dta")
names(df)
