## ----------------------------------------------------
## Session 3 — Interactive maps and mixed data sources
## ----------------------------------------------------
## Goals:
## 1) Create basic leaflet map
## 2) Build a local map with points, lines, polygons
## 3) Add web data layers
## 4) Create a fully functional interactive map
## 5) Extra: add raster data


## --------------------------
## Setup: packages + folders
## --------------------------

# Set WD
setwd("~/GIS plan/Data")

# Load libraries
library(leaflet)            # interactive maps
library(leaflet.extras)     # extra leaflet functions  
library(leaflet.extras2)    # extra leaflet functions
library(leafem)             # to map raster data
library(stars)              # for raster and spatiotemporal data
library(esri2sf)            # ArcGIS FeatureServer -> sf
library(leaflet.providers)  # leaflet basemaps
library(sf)                 # spatial data  
library(rnaturalearth)      # Natural Earth basemap

# Leaflet expects WGS84 lon/lat
target_crs <- 4326


## ------------------
## Basic leaflet map
## ------------------

# Basic leaflet map
leaflet() %>%
  addTiles()

# Leaflet map with a marker
leaflet() %>%
  addTiles() %>%
  addMarkers(lng = -0.1276, lat = 51.5074)

# Leaflet map with baselayers
leaflet() %>%
  addProviderTiles(providers$OpenStreetMap, group = "OSM") %>%
  addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") %>%
  addMarkers(lng = -0.1276, lat = 51.5074, popup = "London") %>%
  addLayersControl(
    baseGroups = c("OSM","Satellite"),
    options = layersControlOptions(collapsed = FALSE))


## ----------------------
## Build the a local map 
## ----------------------

# Load local data
point_sf <- st_read("point.geojson")
line_sf  <- st_read("line.geojson")
polygon_sf <- st_read("polygon.geojson")

# Create leaflet map
leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron, group = "Carto") %>%
  addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") %>%
  addCircleMarkers(
    data = point_sf,
    color = "blue",
    radius = 5,
    popup = ~paste("Name", Name),
    group = "Point") %>%
  addPolylines(
    data = line_sf,
    color = "green",
    weight = 3,
    popup = ~paste("Name", Name),
    group = "Line") %>%
  addPolygons(
    data = polygon_sf,
    color = "red",
    weight = 2,
    fillOpacity = 0.5,
    popup = ~paste("Name", Name),
    group = "Polygon") %>%
  addLayersControl(
    baseGroups = c("Carto","Satellite"),
    overlayGroups = c("Point","Line","Polygon"),
    options = layersControlOptions(collapsed = FALSE)) %>%
  hideGroup("Line") %>%
  hideGroup("Polygon")


## ---------
## Web data
## ---------

# Thames
thames <- esri2sf::esri2sf(
  "https://services6.arcgis.com/cFcfnHqSdtEfYu8A/arcgis/rest/services/thames_estuary_new/FeatureServer/0",
  where = "1=1") %>%
  st_transform(target_crs)

leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron, group = "Carto") %>%
  addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") %>%
  addPolygons(
    data = thames,
    fillColor = "darkblue",
    color = NA,
    group = "Thames Estuary") %>%
  addCircleMarkers(
    data = point_sf,
    color = "blue",
    radius = 5,
    popup = ~paste("Name", Name),
    group = "Point") %>%
  addPolylines(
    data = line_sf,
    color = "green",
    weight = 3,
    popup = ~paste("Name", Name),
    group = "Line") %>%
  addPolygons(
    data = polygon_sf,
    color = "red",
    weight = 2,
    fillOpacity = 0.5,
    popup = ~paste("Name", Name),
    group = "Polygon") %>%
  addLayersControl(
    baseGroups = c("Carto","Satellite"),
    overlayGroups = c("Point","Line","Polygon", "Thames Estuary"),
    options = layersControlOptions(collapsed = FALSE)) %>%
  addResetMapButton() %>%
  addFullscreenControl() %>%
  hideGroup("Line") %>%
  hideGroup("Polygon")


# Earthquakes
eq <- st_read("https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_day.geojson", quiet = TRUE) # reading the data without printing the usual progress/info messages to the console

leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron, group = "Carto") %>%
  addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") %>%
  addCircleMarkers(
    data = eq,
    color = "red",
    radius = ~mag,
    popup = ~paste("Location:", place, "<br>",
                   "Magnitude:", mag, "<br>",
                   "Date:", as.character(as.POSIXct(time/1000, origin="1970-01-01"))),
    group = "Earthquakes") %>%
  addLayersControl(
    baseGroups = c("Carto","Satellite"),
    overlayGroups = c("Earthquakes"),
    options = layersControlOptions(collapsed = FALSE)) %>%
  addLegend(
    position = "bottomright",
    colors = "red",
    labels = "Circle size proportional to magnitude",
    opacity = 1) %>%
  addResetMapButton() %>%
  addFullscreenControl()

# Fault lines
faults <- esri2sf::esri2sf(
  "https://services.arcgis.com/jIL9msH9OI208GCb/ArcGIS/rest/services/Active_Faults/FeatureServer/0",
  where = "1=1") %>%
  st_transform(target_crs)

leaflet() %>%
  setView(lng = 63, lat = 28, zoom = 2) %>%
  addProviderTiles(providers$CartoDB.DarkMatter, group = "Carto Dark") %>%
  addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") %>%
  addPolylines(
    data = faults,
    color = "orange",
    weight = 2,
    group = "Faults") %>%
  addCircleMarkers(
    data = eq,
    color = "red",
    fillOpacity = 1,
    radius = ~mag,
    popup = ~paste("Location:", place, "<br>",
                   "Magnitude:", mag, "<br>",
                   "Date:", as.character(as.POSIXct(time/1000, origin="1970-01-01"))), # this converts a numeric Unix timestamp (usually in milliseconds) into a human-readable date and time, it sets January 1, 1970, as the "zero" point for the calculation
    group = "Earthquakes") %>%
  addLayersControl(
    baseGroups = c("Carto Dark","Satellite"),
    overlayGroups = c("Earthquakes", "Faults"),
    options = layersControlOptions(collapsed = FALSE)) %>%
  addLegend(
    position = "bottomright",
    colors = c("red", "orange"),
    labels = c("Circle size proportional to magnitude", "Fault lines"),
    opacity = 1) %>%
  addResetMapButton() %>%
  addFullscreenControl()


## ----------------------------------------------------------------------------
## Extra: add raster data: https://neo.gsfc.nasa.gov/view.php?datasetId=MYD28M
## ----------------------------------------------------------------------------

# Load raster
tif_path <- "MYD28M_2025-11-01_rgb_3600x1800.TIFF"
sst_raster <- read_stars(tif_path)

# Set CRS
st_crs(sst_raster) <- 4326

# Adjust dimensions (georeferencing)
attr(sst_raster, "dimension")$x$offset <- -180 # sets the starting coordinates 
attr(sst_raster, "dimension")$y$offset <- 90
attr(sst_raster, "dimension")$x$delta <- 0.1  # pixel size (resolution), each pixel represents 0.1 degrees
attr(sst_raster, "dimension")$y$delta <- -0.1 

# Replace no data values with NA
sst_raster[sst_raster == 255] <- NA 

# Create color palette
pal <- colorNumeric(
  palette = "RdYlBu", 
  domain = c(1, 254), 
  reverse = TRUE,
  na.color = "transparent")

# Load world borders
world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")

# Create leaflet map with raster
leaflet() %>%
  addTiles() %>%
  setView(lng = 13, lat = 28, zoom = 2) %>%
  addStarsImage(
    sst_raster, 
    colors = pal, 
    opacity = 0.8, 
    project = TRUE) %>%
  addPolygons(
    data = world,
    color = "black", weight = 1, fillOpacity = 0,
    group = "Borders") %>%
  addLegend(
    pal = colorNumeric("RdYlBu", domain = c(0, 35), reverse = TRUE), 
    values = c(0, 35),
    title = "SST (°C)",
    position = "bottomright")


# End session 3
