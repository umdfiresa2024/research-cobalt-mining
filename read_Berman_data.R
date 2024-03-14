library("haven")
library("tidyverse")
library("foreign")
library("terra")

data_dir <- "/Users/lukemorelli/documents/research-cobalt-mining/20150774_data/Data"
ipis_dir <- "/Users/lukemorelli/documents/research-cobalt-mining/IPIS_Data"
eth_dir <- "/Users/lukemorelli/documents/research-cobalt-mining/GREG"
dir(eth_dir)
ipis_pth <- paste(ipis_dir, "/cod_mines_curated_all_opendata_p_ipis.csv", sep = "")
eth_df_pth <- paste(eth_dir, "/GREG.dbf", sep = "")
eth_shp_pth <- paste(eth_dir, "/GREG.shp", sep = "")
eth_up_pth <- paste("/Users/lukemorelli/documents/research-cobalt-mining", "/GeoEPR-2021.csv", sep = "")
eth_conf_pth <- paste("/Users/lukemorelli/documents/research-cobalt-mining", "/ACD2EPR-2021.csv", sep = "")
cobalt_pth <- paste("/Users/lukemorelli/documents/research-cobalt-mining", "/cobalt_data.csv", sep = "")
copper_pth <- paste("/Users/lukemorelli/documents/research-cobalt-mining", "/copper_data.csv", sep = "")

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
plot(eth_data_congo, xlab = "Latitude", ylab = "Longitude")
text(coords, labels=groupnames, cex=0.6)

df_updated_eth <- read.csv(eth_up_pth) 
df_up_congo <- df_updated_eth %>%
  filter(statename == "Congo, Democratic Republic of (Zaire)")

df_eth_conf <- read.csv(eth_conf_pth)
df_conf_congo <- df_eth_conf %>%
  filter(statename == "Congo, Democratic Republic of (Zaire)")

cobalt_prices <- read.csv(cobalt_pth)
copper_prices <- read.csv(copper_pth)
