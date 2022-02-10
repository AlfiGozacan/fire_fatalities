# Load libraries --------------

library(tidyverse)
library(RODBC)
library(leaflet)
library(rgdal)
library(plotly)

# Load data -------------------

scores <- read.csv("C:/Users/agozacan/OneDrive - Humberside Fire and Rescue Service/Fire Fatality Profiling/Input and Output/output.csv")

scores = scores[-which(scores$Mosaic_Type == ""),]

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

dbhandle2 <- odbcDriverConnect("driver={SQL Server};
                              server=HQCFRMISSQL;
                              database=CFRMIS_HUMBS;
                              trusted_connection=true")

old_scores <- sqlQuery(dbhandle2,
                       "select UPRN, Easting, Northing, Type_Desc, Total_Prio, Final_Prio
                       from MosaicCurrent
                       ")

old_scores = old_scores[-which(old_scores$Type_Desc == "U-99"),]

old_ranks <- data.frame("Total_Prio" = unique(old_scores$Total_Prio))

for (i in 1:length(old_ranks$Total_Prio)) {
  
  old_ranks$rank[i] = which(sort(old_ranks$Total_Prio) == old_ranks$Total_Prio[i])
  
}
remove(i)

# The Mosaic types recorded in MosaicCurrent are from Mosaic UK 7, whereas INCIDENTS uses Mosaic Public Sector -----------

old_scores %>%
  right_join(incidents %>%
              mutate(UPRN = as.numeric(UPRN)) %>%
              select(UPRN, CALLDATE, NUMBER_OF_CASUALTIES, NUMBER_OF_FATALITIES, RESCUES),
            by="UPRN")

# Make plots -----------------

# Count number of dwellings by priority score
scores %>%
  count(Final_Score) %>%
  arrange(Final_Score)

old_scores %>%
  count(Final_Prio) %>%
  arrange(Final_Prio)

# Score distribution
p <- scores %>%
  ggplot(aes(Final_Score)) +
  geom_density()

ggplotly(p)

# Score rank distribution (higher score equates to lower rank)
p <- scores %>%
  left_join(ranks, by="Final_Score") %>%
  ggplot(aes(rank)) +
  geom_histogram(bins=76)

ggplotly(p)

# Proportion of incidents with casualties / fatalities by score rank
p <- scores %>%
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

ggplotly(p)

# Proportion of incidents with casualties / fatalities by score ntile
p <- scores %>%
  mutate(ntile = ntile(Final_Score, 9)) %>%
  left_join(incidents %>%
              mutate(UPRN = as.numeric(UPRN)) %>%
              select(UPRN, CALLDATE, NUMBER_OF_CASUALTIES, NUMBER_OF_FATALITIES),
            by="UPRN") %>%
  replace_na(list(NUMBER_OF_CASUALTIES = 0, NUMBER_OF_FATALITIES = 0)) %>%
  group_by(ntile) %>%
  summarise(total_casualties = sum(NUMBER_OF_CASUALTIES),
            total_fatalities = sum(NUMBER_OF_FATALITIES)) %>%
  mutate(total_casfat = total_casualties + total_fatalities) %>%
  ggplot(aes(as.factor(ntile), total_casfat)) +
  geom_col(fill="royalblue") +
  ggtitle("Number of incidents involving a casualty or a fatality in Humberside by 9-tile (Proposed Model)") +
  xlab("9-tile (higher score equates to higher risk)") +
  ylab("Number of Casualty or Fatality Incidents")

p <- old_scores %>%
  left_join(old_ranks, by="Total_Prio") %>%
  left_join(incidents %>%
              mutate(UPRN = as.numeric(UPRN)) %>%
              select(UPRN, CALLDATE, NUMBER_OF_CASUALTIES, NUMBER_OF_FATALITIES),
            by="UPRN") %>%
  replace_na(list(NUMBER_OF_CASUALTIES = 0, NUMBER_OF_FATALITIES = 0)) %>%
  group_by(Final_Prio, rank) %>%
  summarise(total_casualties = sum(NUMBER_OF_CASUALTIES),
            total_fatalities = sum(NUMBER_OF_FATALITIES),
            frequency = n()) %>%
  mutate(total_casfat = total_casualties + total_fatalities) %>%
  mutate(propn_casfat = total_casfat / frequency) %>%
  ggplot(aes(reorder(Final_Prio, rank), propn_casfat)) +
  geom_col(fill="tomato") +
  ggtitle("Proportion of households where a casualty or fatality has been recorded by priority score (Current Model)") +
  xlab("Priority Score") +
  ylab("Proportion of Households")

ggplotly(p)

# Proportion and number of incidents with casualties / fatalities by Mosaic type
p <- scores %>%
  left_join(incidents %>%
              mutate(UPRN = as.numeric(UPRN)) %>%
              select(UPRN, CALLDATE, NUMBER_OF_CASUALTIES, NUMBER_OF_FATALITIES),
            by="UPRN") %>%
  replace_na(list(NUMBER_OF_CASUALTIES = 0, NUMBER_OF_FATALITIES = 0)) %>%
  group_by(Mosaic_Type) %>%
  summarise(prop = (sum(NUMBER_OF_CASUALTIES) + sum(NUMBER_OF_FATALITIES)) / n()) %>%
  ggplot(aes(reorder(Mosaic_Type, -prop), prop)) +
  geom_col() +
  ggtitle("Proportion of households where a casualty or fatality has been recorded by Mosaic type") +
  xlab("Mosaic Type") +
  ylab("Proportion of Households") +
  theme(axis.text.x = element_text(angle = 90))

p <- scores %>%
  left_join(incidents %>%
              mutate(UPRN = as.numeric(UPRN)) %>%
              select(UPRN, CALLDATE, NUMBER_OF_CASUALTIES, NUMBER_OF_FATALITIES),
            by="UPRN") %>%
  replace_na(list(NUMBER_OF_CASUALTIES = 0, NUMBER_OF_FATALITIES = 0)) %>%
  group_by(Mosaic_Type) %>%
  summarise(freq = sum(NUMBER_OF_CASUALTIES) + sum(NUMBER_OF_FATALITIES)) %>%
  ggplot(aes(reorder(Mosaic_Type, -freq), freq)) +
  geom_col() +
  ggtitle("Number of households where a casualty or fatality has been recorded by Mosaic type") +
  xlab("Mosaic Type") +
  ylab("Number of Households") +
  theme(axis.text.x = element_text(angle = 90))

ggplotly(p)

# Average final score by Mosaic type
p <- scores %>%
  group_by(Mosaic_Type) %>%
  summarise(avg_score = mean(Final_Score)) %>%
  ggplot(aes(reorder(Mosaic_Type, -avg_score), avg_score)) +
  geom_col(fill="royalblue") +
  ggtitle("Average Risk Score by Mosaic Type (Proposed Model)") +
  xlab("Mosaic Type") +
  ylab("Average Score") +
  theme(axis.text.x = element_text(angle = 90))

p <- old_scores %>%
  group_by(Type_Desc) %>%
  summarise(avg_score = mean(Total_Prio)) %>%
  ggplot(aes(reorder(Type_Desc, -avg_score), avg_score)) +
  geom_col(fill="tomato") +
  ggtitle("Average Risk Score by Mosaic Type (Current Model)") +
  xlab("Mosaic Type") +
  ylab("Average Score") +
  theme(axis.text.x = element_text(angle = 90))

p <- old_scores %>%
  group_by(Type_Desc) %>%
  summarise(avg_score = median(Total_Prio)) %>%
  ggplot(aes(reorder(Type_Desc, -avg_score), avg_score)) +
  geom_col()

ggplotly(p)

# Number of dwellings by Mosaic type
p <- scores %>%
  group_by(Mosaic_Type) %>%
  summarise(total = n()) %>%
  ggplot(aes(reorder(Mosaic_Type, -total), total)) +
  geom_col()

ggplotly(p)

# Number of high-priority dwellings by Mosaic type
p <- scores %>%
  mutate(high_priority = (Final_Score > 130)) %>%
  group_by(Mosaic_Type) %>%
  summarise(total = sum(high_priority)) %>%
  filter(total > 0) %>%
  ggplot(aes(reorder(Mosaic_Type, -total), total)) +
  geom_col()

ggplotly(p)

# Proportion of high-priority dwellings by Mosaic type
p <- scores %>%
  mutate(high_priority = (Final_Score > 130)) %>%
  group_by(Mosaic_Type) %>%
  summarise(total = sum(high_priority),
            prop = sum(high_priority) / n()) %>%
  filter(prop > 0) %>%
  ggplot(aes(reorder(Mosaic_Type, -prop), prop)) +
  geom_col(fill="royalblue") +
  ggtitle("Proportion of high-priority dwellings by Mosaic type (with total number of high-piority dwellings)") +
  xlab("Mosaic Type") +
  ylab("Proportion") +
  geom_label(aes(label=total), nudge_y = -.01, fill="white")

p <- old_scores %>%
  mutate(high_priority = (Total_Prio == 22)) %>%
  group_by(Type_Desc) %>%
  summarise(total = sum(high_priority),
            prop = sum(high_priority) / n()) %>%
  filter(prop > 0) %>%
  ggplot(aes(reorder(Type_Desc, -prop), prop)) +
  geom_col(fill="tomato") +
  ggtitle("Proportion of high-priority dwellings by Mosaic type (with total number of high-piority dwellings)") +
  xlab("Mosaic Type") +
  ylab("Proportion") +
  geom_label(aes(label=total), nudge_y = -.01, fill="white")

ggplotly(p)

# Make map of high-priority areas -----------------

# Convert new coords
coords.EPSG.27700 = SpatialPoints(cbind(scores[scores$Final_Score > 130,]$Easting, scores[scores$Final_Score > 130,]$Northing), proj4string=CRS("+init=epsg:27700"))                                                                                      # Easting / Northing
coords.EPSG.4326 <- spTransform(coords.EPSG.27700, CRS("+init=epsg:4326"))                                     # Long / Lat

# Convert old coords
coords.EPSG.27700 = SpatialPoints(cbind(old_scores[old_scores$Total_Prio == 22,]$Easting, old_scores[old_scores$Total_Prio == 22,]$Northing), proj4string=CRS("+init=epsg:27700"))                                                                                      # Easting / Northing
coords.EPSG.4326 <- spTransform(coords.EPSG.27700, CRS("+init=epsg:4326"))     

leaflet() %>%
  addTiles() %>%
  addMarkers(data = as.data.frame(coords.EPSG.4326),
             lng = ~coords.x1,
             lat = ~coords.x2,
             clusterOptions = markerClusterOptions())
