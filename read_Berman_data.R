library("haven")
library("tidyverse")

dir("20150774_data/Data/")
df<-read_dta("20150774_data/Data/BCRT_baseline.dta")
names(df)

lon<-unique(df$longitude)
lon<-subset(lon, lon>0)
lat<-unique(df$latitude) 

coord<-crossing(lon, lat)

library("terra")

x <- vect(coord, geom=c("lon", "lat"),
          crs="+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs ")
r<-rast(x)
plot(r)

library("tmap")
tm_shape(r)+
  tm_raster(col="red")
