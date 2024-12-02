library("haven")
library("tidyverse")
library("foreign")
library("terra")

data_dir <- "/Users/lukemorelli/documents/research-cobalt-mining/20150774_data/Data"
ipis_dir <- "/Users/lukemorelli/documents/research-cobalt-mining/IPIS_Data"
eth_dir <- "/Users/lukemorelli/documents/research-cobalt-mining/GREG"
permits_dir <- paste("/Users/lukemorelli/documents/research-cobalt-mining", "/mining_permits", sep="")
ipis_pth <- paste(ipis_dir, "/cod_mines_curated_all_opendata_p_ipis.csv", sep = "")
eth_df_pth <- paste(eth_dir, "/GREG.dbf", sep = "")
eth_shp_pth <- paste(eth_dir, "/GREG.shp", sep = "")
eth_up_pth <- paste("/Users/lukemorelli/documents/research-cobalt-mining", "/GeoEPR-2021.csv", sep = "")
eth_conf_pth <- paste("/Users/lukemorelli/documents/research-cobalt-mining", "/ACD2EPR-2021.csv", sep = "")
cobalt_pth <- paste("/Users/lukemorelli/documents/research-cobalt-mining", "/cobalt_data.csv", sep = "")
copper_pth <- paste("/Users/lukemorelli/documents/research-cobalt-mining", "/copper_data.csv", sep = "")
conflicts_pth <- "/Users/lukemorelli/documents/research-cobalt-mining/DRC_conflicts.csv"
df_berman_pth <- paste(data_dir, "/BCRT_baseline.dta", sep="")
df_permits_pth <- paste(permits_dir, "/Democratic_Republic_of_the_Congo_mining_permits.dbf", sep="")
df_permits_shape_pth <- paste(permits_dir, "/Democratic_Republic_of_the_Congo_mining_permits.shp", sep="")
borders_pth <- ("/Users/lukemorelli/documents/research-cobalt-mining/DRC_admin_borders/democratic_republic_of_the_congo_administrative.shp")


ipis_data <- read.csv(ipis_pth)

df_visit <- ipis_data %>%
  group_by(pcode) %>%
  summarize(first_visit = min(visit_date), last_visit = max(visit_date))

df_clean <- ipis_data %>%
  group_by(pcode) %>%
  arrange(desc(visit_date)) %>% 
  slice(1) # Only continue with the most recent visit for each mine

df_merged <- merge(df_visit, df_clean, by="pcode", all.x = TRUE)

df_cobalt <- df_clean %>%
  filter(str_detect(mineral1, "Cobalt") | str_detect(mineral2, "Cobalt") | str_detect(mineral3, "Cobalt"))

df_cobalt_visit <- df_merged %>%
  filter(str_detect(mineral1, "Cobalt") | str_detect(mineral2, "Cobalt") | str_detect(mineral3, "Cobalt"))

df_eth <- read.dbf(eth_df_pth) 
df_eth_congo <- df_eth %>%
  filter(FIPS_CNTRY == "CG")

eth_shp <- vect(eth_shp_pth)
eth_data <- project(eth_shp, "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
eth_data_congo <- eth_data[eth_data$FIPS_CNTRY == "CG"]

g2name <- ifelse(eth_data_congo$G2ID==0, "", paste(", ",eth_data_congo$G2SHORTNAM, sep = ""))
g3name <- ifelse(eth_data_congo$G3ID==0, "", paste(", ",eth_data_congo$G3SHORTNAM, sep = ""))
groupnames <- paste(eth_data_congo$G1SHORTNAM, g2name, g3name, sep = "")
coords <- centroids(eth_data_congo)
plot(eth_data_congo, xlab = "Latitude", ylab = "Longitude", main = "Ethnic Group Boundaries in the DRC")
text(coords, labels=groupnames, cex=0.6)

df_updated_eth <- read.csv(eth_up_pth) 
df_up_congo <- df_updated_eth %>%
  filter(statename == "Congo, Democratic Republic of (Zaire)")

df_eth_conf <- read.csv(eth_conf_pth)
df_conf_congo <- df_eth_conf %>%
  filter(statename == "Congo, Democratic Republic of (Zaire)")

cobalt_prices <- read.csv(cobalt_pth)
copper_prices <- read.csv(copper_pth)

df_initial_conflicts <- read.csv(conflicts_pth)

df_permits <- read.dbf(df_permits_pth)
vect_permits_shape <- vect(df_permits_shape_pth, crs="+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")

date_start <- as.Date("2019-05-01")
date_end <- as.Date("2020-10-31")

df_conflicts <- df_initial_conflicts %>%
  mutate(event_date = as.Date(event_date, format = "%d %B %Y")) %>%
  filter(event_date >= date_start & event_date <= date_end) 

conflicts_shp <- vect(df_conflicts, geom=c("longitude", "latitude"), crs = "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
  
df_copper_permits <- df_permits %>%
  filter(!is.na(date_do), !is.na(date_de1)) %>%
  mutate(date_do = as.Date(date_do), date_de1 = as.Date(date_de1)) %>%
  filter(date_do <= date_start & date_de1 >= date_end) %>%
  mutate(resource=as.character(resource)) %>%
  filter(str_detect(resource, "Cu"))

shp_cobalt_mine <- vect(df_cobalt_visit, geom=c("longitude", "latitude"), crs="+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
cobalt_centers <- centroids(shp_cobalt_mine)
cobalt_areas <- buffer(cobalt_centers, width=2500, capstyle="round")

copper_mines <- merge(vect_permits_shape, df_copper_permits, by="objectid", all.y="true")

borders<-vect(borders_pth)
admin_borders <- borders[borders$ADMIN_LEVE==2]
plot(admin_borders, main = "Map of Conflicts between May 2019 and October 2020 overlayed with Cobalt Mines in the DRC", cex.main = 0.55, xlab = "Longitude", ylab = "Latitude")
plot(conflicts_shp, col = "red", add=TRUE)

lines(copper_mines, col="blue")
points(shp_cobalt_mine, col="red")
legend("topleft", legend = c("Copper", "Cobalt"), col = c("red", "blue"), pch = 16, cex=0.75)

all_intersections <- data.frame()
for(i in 1:nrow(copper_mines)) {
  copper_mine <- copper_mines[i,]
  intersections_cobalt <- terra::relate(copper_mine, shp_cobalt_mine, relation="intersects")
  intersections_cobalt_vec <- as.vector(intersections_cobalt)
  intersection_cobalt <- df_cobalt_visit[intersections_cobalt_vec,]
  if (nrow(intersection_cobalt) > 0) {
    intersection_cobalt$objectid <- copper_mine$objectid
    all_intersections <- rbind(all_intersections, intersection_cobalt)
  }
}
all_conflicts <- data.frame()
all_tribes <- data.frame()
for(i in 1:nrow(cobalt_areas)) {
  cobalt_mine <- cobalt_areas[i,]
  intersections_tribes <- terra::relate(cobalt_mine, eth_data_congo, relation="within")
  intersections_conflicts <- terra::relate(cobalt_mine, conflicts_shp, relation="intersects")
  intersection_tribes_vec <- as.vector(intersections_tribes)
  intersections_conflict_vec <- as.vector(intersections_conflicts)
  intersection_tribes <- df_eth_congo[intersection_tribes_vec,]
  intersection_conflict <- df_conflicts[intersections_conflict_vec,]
  if (nrow(intersection_conflict) > 0) {
    intersection_conflict$pcode <- cobalt_mine$pcode
    all_conflicts <- rbind(all_conflicts, intersection_conflict)
  }
  if (nrow(intersection_tribes) > 0) {
    intersection_tribes$pcode <- cobalt_mine$pcode
    all_tribes <- rbind(all_tribes, intersection_tribes)
  }
}

df_cobalt_intersection <- all_intersections %>%
  group_by(pcode) %>%
  summarize(objectid = first(objectid))
df_copper_parties = merge(df_cobalt_intersection, df_copper_permits, by="objectid", all.Y=TRUE) %>%
  group_by(pcode) 
df_copper_parties <- df_copper_parties[,c("pcode","objectid", "parties")]

df_conflict_intersections <- all_conflicts %>%
  group_by(pcode) %>%
  summarize(num_conflicts = n())

df_tribe_intersections <- all_tribes[, c("pcode", "G1LONGNAM")]

final_df <- merge(df_copper_parties, df_cobalt_visit, by="pcode", all.y=TRUE)
final_df_finished <- merge(df_conflict_intersections, final_df, by="pcode", all.y=TRUE) %>%
  group_by(pcode) %>%
  mutate(parties = as.character(parties)) %>%
  summarize(num_conflicts = ifelse(is.na(num_conflicts), 0, num_conflicts), 
            in_copper_mine = ifelse(is.na(objectid), 0, 1), 
            company = ifelse(is.na(parties), "", first(parties)))
final_df_finished$copper_conflicts <- c(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0)
head(final_df_finished)

shp_cobalt_mine$legend<-"Artisanal Cobalt Mine"
copper_mines$legend<-"Industrial Copper Mine"

png("/Users/lukemorelli/documents/research-cobalt-mining/mines.png", width=1000, height = 500, units = "px")
plot(shp_cobalt_mine, main = "Locations of Industrial Copper Mines (in Red) and Artisanal Cobalt Mines (in Blue) in the DRC", cex.main = 0.8,
     col="blue", cex = 0.7, xlab = "Longitude", ylab = "Latitude")
lines(copper_mines, col="red")
#legend("bottomleft", legend = c("Industrial Copper Mines", "Artisanal Cobalt Mines"), 
       #fill = c("red", "blue"), cex = 1, box.col = "brown", lty = 1)
dev.off()

final_results_df <- final_df_finished %>%
  mutate(in_copper_mine = as.factor(in_copper_mine)) %>%
  group_by(in_copper_mine) %>%
  summarize(num_conflicts = mean(num_conflicts), num_mines = n())


df5<-final_df_finished %>%
  mutate(obs=1) %>%
  group_by(company) %>%
  summarize(average_conflicts = mean(num_conflicts), num_mines=sum(obs))

ggplot(data = final_df_finished, 
       aes(x = in_copper_mine, y = num_conflicts, col = company)) + geom_point()
ggsave("/Users/lukemorelli/documents/research-cobalt-mining/plot.png", width = 1000, height = 1000, units = "px")

ggplot(data = final_results_df, aes(x=in_copper_mine, y=num_conflicts)) + geom_col(fill="red") + ylab("Number of Conflicts") +
  ggtitle("Average Number of Conflicts for Artisanal Cobalt Mines within \n and outside the Boundaries of Industrial Copper Mines") +
  theme(plot.title = element_text(size=12, face="bold", hjust = 0.5))

ggplot(data = df5, aes(x=company, y=average_conflicts)) + geom_col()
