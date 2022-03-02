# Load libraries --------------

library(tidyverse)
library(RODBC)
library(leaflet)
library(rgdal)
library(sf)
library(htmltools)

# Load data -------------------

scores <- read.csv("C:/Users/agozacan/OneDrive - Humberside Fire and Rescue Service/Fire Fatality Profiling/Input and Output/output.csv")

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

lsoas <- readOGR("C:/Users/agozacan/OneDrive - Humberside Fire and Rescue Service/GIS/Shapefiles/Lower_Layer_Super_Output_Areas_(December_2011)_Boundaries_Generalised_Clipped_(BGC)_EW_V3.shp")

lsoas2 <- st_read("C:/Users/agozacan/OneDrive - Humberside Fire and Rescue Service/GIS/Shapefiles/Lower_Layer_Super_Output_Areas_(December_2011)_Boundaries_Generalised_Clipped_(BGC)_EW_V3.shp")

lsoas2 <- st_transform(lsoas2, crs=4326)

lsoa_data <- as.data.frame(lsoas@data)

# Analyse data ------------

map_type = "new"

# Convert new coords
if (map_type == "new") {
  coords.EPSG.27700 = SpatialPoints(cbind(scores$Easting, scores$Northing), proj4string=CRS("+init=epsg:27700"))
  coords.EPSG.4326 <- spTransform(coords.EPSG.27700, CRS("+init=epsg:4326"))
} else if (map_type == "old") {
  coords.EPSG.27700 = SpatialPoints(cbind(old_scores$Easting, old_scores$Northing), proj4string=CRS("+init=epsg:27700"))
  coords.EPSG.4326 <- spTransform(coords.EPSG.27700, CRS("+init=epsg:4326"))
} else {
  coords.EPSG.27700 = SpatialPoints(cbind(incidents$EASTING, incidents$NORTHING), proj4string=CRS("+init=epsg:27700"))
  coords.EPSG.4326 <- spTransform(coords.EPSG.27700, CRS("+init=epsg:4326"))
}

# Plot points
# plot(lsoas)
# plot(coords.EPSG.27700, pch=21, cex=.5, col="red", add=TRUE)

# Calculate average score in each LSOA polygon
if (map_type == "new") {
  
  scores$LSOA11CD <- over(coords.EPSG.27700, lsoas)$LSOA11CD
  
  lsoa_data <- lsoa_data %>%
    inner_join(
      scores %>%
        group_by(LSOA11CD) %>%
        summarise(avg_score = mean(Final_Score)),
      by="LSOA11CD")
  
} else if (map_type == "old") {
  
  old_scores$LSOA11CD <- over(coords.EPSG.27700, lsoas)$LSOA11CD
  
  lsoa_data <- lsoa_data %>%
    inner_join(
      old_scores %>%
        group_by(LSOA11CD) %>%
        summarise(avg_score = mean(Total_Prio)),
      by="LSOA11CD")
  
} else {
  
  incidents$LSOA11CD <- over(coords.EPSG.27700, lsoas)$LSOA11CD
  
  lsoa_data <- lsoa_data %>%
    inner_join(
      incidents %>%
        replace_na(list(NUMBER_OF_CASUALTIES = 0, NUMBER_OF_FATALITIES = 0)) %>%
        select(-GDB_GEOMATTR_DATA) %>%
        group_by(LSOA11CD) %>%
        summarise(avg_score = sum(NUMBER_OF_FATALITIES) + sum(NUMBER_OF_CASUALTIES)),
      by="LSOA11CD")
  
}

lsoas <- lsoas[lsoas$LSOA11CD %in% over(coords.EPSG.27700, lsoas)$LSOA11CD,]

lsoas2 <- lsoas2[lsoas2$LSOA11CD %in% over(coords.EPSG.27700, lsoas)$LSOA11CD,]

# Plot colour map
rbPal <- colorRampPalette(c("lightgreen", "red"))

nbreaks = 32
lsoa_data$colour <- rbPal(nbreaks)[as.numeric(cut(lsoa_data$avg_score, breaks=nbreaks))]

pal <- colorNumeric(
  palette = c("lightgreen", "red"),
  domain = lsoa_data$avg_score
)

leaflet(options = leafletOptions(zoomSnap = 0.25)) %>%
  addTiles() %>%
  addPolygons(data=lsoas2,
              color=lsoa_data$colour,
              opacity=1,
              weight=1,
              fillOpacity=0.5,
              label = lapply(paste0("Average Score: ", as.list(lsoa_data$avg_score)), HTML)) %>%
  addLegend(position="topright",
            pal=pal,
            values=lsoa_data$avg_score,
            title="Average Score",
            opacity=1
  )
