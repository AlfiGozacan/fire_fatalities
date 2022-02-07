# Load libraries --------------

library(tidyverse)
library(RODBC)
library(leaflet)
library(rgdal)

# Load data -------------------

scores <- read.csv("C:/Users/agozacan/OneDrive - Humberside Fire and Rescue Service/Fire Fatality Profiling/Data/final_scores_with_othercircs.csv")

ranks <- data.frame("Final_Score" = unique(scores$Final_Score))

for (i in 1:length(ranks$Final_Score)) {
  
  ranks$rank[i] = which(sort(ranks$Final_Score) == ranks$Final_Score[i])
  
}
remove(i)

dbhandle <- odbcDriverConnect("driver={ODBC Driver 17 for SQL Server};
                              server=humbarcgissql.6aae29eceb48.database.windows.net;
                              database=HumbsArcGIS;
                              uid=agozacan;
                              pwd=P@ssw0rd")

incidents <- sqlQuery(dbhandle,
                      "select *
                      from incidents
                      where NUMBER_OF_CASUALTIES > 0
                      or NUMBER_OF_FATALITIES > 0")

# Make plots -----------------

# Score distribution
scores %>%
  ggplot(aes(Final_Score)) +
  geom_density()

# Score rank distribution (higher score equates to lower rank)
scores %>%
  left_join(ranks, by="Final_Score") %>%
  ggplot(aes(rank)) +
  geom_density()

# Proportion of incidents with casualties / fatalities by score rank (76-tile)
scores %>%
  left_join(ranks, by="Final_Score") %>%
  left_join(incidents %>%
              mutate(UPRN = as.numeric(UPRN)) %>%
              select(UPRN, CALLDATE, NUMBER_OF_CASUALTIES, NUMBER_OF_FATALITIES),
            by="UPRN") %>%
  replace_na(list(NUMBER_OF_CASUALTIES = 0, NUMBER_OF_FATALITIES = 0)) %>%
  group_by(rank) %>%
  summarise(total_casualties = sum(NUMBER_OF_CASUALTIES),
            total_fatalities = sum(NUMBER_OF_FATALITIES),
            frequency = n()) %>%
  mutate(total_casfat = total_casualties + total_fatalities) %>%
  mutate(propn_casualties = total_casualties / frequency,
         propn_fatalities = total_fatalities / frequency,
         propn_casfat = total_casfat / frequency) %>%
  ggplot(aes(rank, propn_casfat)) +
  geom_col()

# Proportion of incidents with casualties / fatalities by score ntile
scores %>%
  mutate(ntile = ntile(Final_Score, 10)) %>%
  left_join(incidents %>%
              mutate(UPRN = as.numeric(UPRN)) %>%
              select(UPRN, CALLDATE, NUMBER_OF_CASUALTIES, NUMBER_OF_FATALITIES),
            by="UPRN") %>%
  replace_na(list(NUMBER_OF_CASUALTIES = 0, NUMBER_OF_FATALITIES = 0)) %>%
  group_by(ntile) %>%
  summarise(total_casualties = sum(NUMBER_OF_CASUALTIES),
            total_fatalities = sum(NUMBER_OF_FATALITIES)) %>%
  mutate(total_casfat = total_casualties + total_fatalities) %>%
  ggplot(aes(ntile, total_casfat)) +
  geom_col()

# Proportion of incidents with casualties / fatalities by Mosaic type
scores %>%
  left_join(incidents %>%
              mutate(UPRN = as.numeric(UPRN)) %>%
              select(UPRN, CALLDATE, NUMBER_OF_CASUALTIES, NUMBER_OF_FATALITIES),
            by="UPRN") %>%
  replace_na(list(NUMBER_OF_CASUALTIES = 0, NUMBER_OF_FATALITIES = 0)) %>%
  group_by(Mosaic_Type) %>%
  summarise(total_casualties = sum(NUMBER_OF_CASUALTIES),
            total_fatalities = sum(NUMBER_OF_FATALITIES)) %>%
  mutate(total_casfat = total_casualties + total_fatalities) %>%
  ggplot(aes(Mosaic_Type, total_casfat)) +
  geom_col()

# Average final score by Mosaic type
scores %>%
  group_by(Mosaic_Type) %>%
  summarise(avg_score = mean(Final_Score)) %>%
  ggplot(aes(Mosaic_Type, avg_score)) +
  geom_col()

# Number of high-priority dwellings by Mosaic type
scores %>%
  filter(Final_Score > 100) %>%
  group_by(Mosaic_Type) %>%
  summarise(count = n()) %>%
  ggplot(aes(Mosaic_Type, count)) +
  geom_col()

# Make map of high-priority areas -----------------

# Convert coords
coords.EPSG.27700 = SpatialPoints(cbind(scores[scores$Final_Score > 130,]$Easting, scores[scores$Final_Score > 130,]$Northing), proj4string=CRS("+init=epsg:27700"))                                                                                      # Easting / Northing
coords.EPSG.4326 <- spTransform(coords.EPSG.27700, CRS("+init=epsg:4326"))                                     # Long / Lat

leaflet() %>%
  addTiles() %>%
  addMarkers(data = as.data.frame(coords.EPSG.4326),
             lng = ~coords.x1,
             lat = ~coords.x2,
             clusterOptions = markerClusterOptions())