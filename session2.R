## ------------------------------------------
## Session 2 — Publication-ready static maps
## ------------------------------------------
## Goals:
## 1) Load local spatial data (points, lines, polygons)
## 2) Combine them in a clean ggplot map
## 3) Add web layers (ArcGIS + Natural Earth)
## 4) Zoom to area of interest
## 5) Export a high-resolution figure
## 6) Extra: custom publication theme function 


## --------------------------
## Setup: packages + folders
## --------------------------

# Set WD
setwd("~/GIS plan/Data")

# Load libraries
library(tidyverse)     # data wrangling + readr
library(sf)            # spatial data
library(ggplot2)       # plotting
library(esri2sf)       # ArcGIS FeatureServer -> sf
library(ggspatial)     # scale bar + north arrow
library(rnaturalearth) # Natural Earth basemap
library(ggthemes)      # extra themes
library(grid)          # unit() for theme spacing


## -------------------
## Local spatial data
## -------------------

# Points from CSV (lon/lat columns)
points_df <- read_csv("points.csv")

points_sf <- st_as_sf(
  points_df,
  coords = c("lon", "lat"),
  crs = 4326) 

# Line from GeoJSON
line_sf <- st_read("line.geojson", quiet = TRUE)  # Suppresses the printed status report that usually details the number of features, fields, and the CRS

# Polygon from Shapefile
polygon_sf <- st_read("layers/POLYGON.shp", quiet = TRUE)


## ----------------------
## Make sure CRS matches
## ----------------------

target_crs <- 4326

points_sf  <- st_transform(points_sf, target_crs)
line_sf    <- st_transform(line_sf, target_crs)
polygon_sf <- st_transform(polygon_sf, target_crs)


## --------------------
## Build a local map 
## --------------------

ggplot() +
  geom_sf(data = polygon_sf, colour = "red3") +
  geom_sf(data = line_sf, linewidth = 0.8) +
  geom_sf(data = points_sf, size = 2) +
  labs(
    title = "Study area with monitoring site and transect",
    subtitle = "An example of a publication-ready static map") 


## ----------------------------------
## Add “type” attributes for legends
## ----------------------------------

# Colors for consistent styling
line_point_cols <- c(
  "Transect" = "green4",
  "Monitoring site" = "red3")

poly_fill_cols <- c(
  "Study area" = "purple4")

# Add type attribute to each layer
points_sf <- points_sf  %>% 
  mutate(type = "Monitoring site")  # mutate() is a core function  used to create, modify, or delete columns in a data frame

line_sf <- line_sf %>% 
  mutate(type = "Transect")

polygon_sf <- polygon_sf %>% 
  mutate(type = "Study area")

# Rebuild map with legends
ggplot() +
  geom_sf(data = polygon_sf, aes(fill = type), colour = NA) +
  geom_sf(data = line_sf, aes(colour = type), linewidth = 0.8) +
  geom_sf(data = points_sf, aes(colour = type), size = 2) +
  scale_colour_manual(values = line_point_cols) +
  scale_fill_manual(values = poly_fill_cols) +
  labs(
    title = "Study area with monitoring site and transect",
    subtitle = "An example of a publication-ready static map")


## -----------------------------------------------
## Web data: Thames estuary (ArcGIS FeatureServer)
## -----------------------------------------------

thames <- esri2sf::esri2sf(
  "https://services6.arcgis.com/cFcfnHqSdtEfYu8A/arcgis/rest/services/thames_estuary_new/FeatureServer/0",
  where = "1=1") %>%
  st_transform(target_crs)

# Build combined map: basemap first, then polygon/lines/points
thames_map <- ggplot() +
  geom_sf(data = thames, fill = "lightblue", colour = NA) +
  geom_sf(data = polygon_sf, aes(fill = type), colour = NA) +
  geom_sf(data = line_sf, aes(colour = type), linewidth = 0.8) +
  geom_sf(data = points_sf, aes(colour = type), size = 2) +
  scale_colour_manual(values = line_point_cols) +
  scale_fill_manual(values = poly_fill_cols) +
  labs(
    title = "Study area with monitoring site and transect",
    subtitle = "Local layers over Thames Estuary web layer") +
  theme_bw()

thames_map


## -------------------------
## Zoom to the point extent
## -------------------------

# Extract the bounding box of the points layer
bbox_pts <- st_bbox(points_sf)

buffer_deg <- 0.05  # this creates a numeric variable to act as a padding amount

# Horizontal limits
xlim <- c(bbox_pts["xmin"] - buffer_deg, bbox_pts["xmax"] + buffer_deg)

# Vertical limits
ylim <- c(bbox_pts["ymin"] - buffer_deg, bbox_pts["ymax"] + buffer_deg)

thames_map_zoom <- thames_map +
  coord_sf(xlim = xlim, ylim = ylim, expand = FALSE) # expand = FALSE prevents ggplot from adding extra padding

thames_map_zoom


## ----------------------------------------------------------
## Web data: Biodiversity hotspots (UNEP-WCMC GeoJSON query)
## ----------------------------------------------------------

target_crs <- 4326

# Read from ArcGIS
hotspots_url <- "https://services.arcgis.com/bL1WyMoaiBW4etad/ArcGIS/rest/services/Biodiversity_Hotspots_2016/FeatureServer/0"

# Load biodiversity hotspots
hotspots_sf <- esri2sf::esri2sf(hotspots_url, where = "1=1") %>% # used to request all records from the dataset without applying any attribute filters
  st_transform(target_crs)

## Natural Earth basemap
world <- ne_countries(scale = "medium", returnclass = "sf") %>%
  st_transform(target_crs)

## Publication map (NOTE: basemap first, then hotspots on top)
hotspots_map <- ggplot() +
  geom_sf(data = hotspots_sf, fill = "tomato", colour = NA, alpha = 0.6) +
  geom_sf(data = world, fill = "grey95", colour = "white", linewidth = 0.2) +
  labs(
    title = "Global Biodiversity Hotspots (2016)",
    subtitle = "Hotspots over a Natural Earth basemap") +
  theme_clean()
  
hotspots_map

# By type
names(hotspots_sf)

hotspots_map <- ggplot() +
  geom_sf(data = world, fill = "grey", colour = "white", linewidth = 0.2) +
  geom_sf(data = hotspots_sf, aes(fill = Type), colour = NA, alpha = 0.7) +
  scale_fill_manual(
    values = c(
      "hotspot area" = "tomato",
      "outer limit"  = "goldenrod")) +
  labs(
    title = "Global Biodiversity Hotspots (2016)",
    subtitle = "Hotspots over a Natural Earth basemap",
    fill = NULL) +
  theme_wsj() # many options available

hotspots_map


## -----------------------------
## Save map (high resolution)
## -----------------------------

ggsave(
  filename = "biodiversity_hotspots_map.png",
  plot = hotspots_map,
  width = 10,
  height = 6,
  units = "in",
  dpi = 300)  # dots per inch, industry standard for "print-ready" quality


## -----------------------------------------
## Extra: Custom publication theme function 
## -----------------------------------------

theme_Publication_map <- function(base_size = 12, base_family = "") {
  
  theme_bw(base_size = base_size, base_family = base_family) +
    theme(
      
      # Titles
      plot.title    = element_text(face = "bold", size = rel(1.2), hjust = 0.5), # sets the font size to be 1.2 times larger than the base font size of the theme. rel() ensures the title scales proportionately
      plot.subtitle = element_text(size = rel(1.0), hjust = 0.5),
      
      # Cleaner without axes and heavy grids
      axis.title = element_blank(),
      axis.text  = element_blank(),
      axis.ticks = element_blank(),
      axis.line  = element_blank(),
      
      # Gridlines off
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      
      # Panel border off
      panel.border = element_blank(),
      
      # Legend styling
      legend.position  = "bottom",
      legend.direction = "horizontal",
      legend.title     = element_text(face = "italic"),
      legend.key       = element_blank(),
      
      # Spacing
      plot.margin = unit(c(10, 8, 6, 8), "mm")
    )
}


hotspots_map <- ggplot() +
  geom_sf(data = world, fill = "grey75", colour = "white", linewidth = 0.2) +
  geom_sf(data = hotspots_sf, aes(fill = Type), colour = NA, alpha = 0.7) +
  scale_fill_manual(
    values = c(
      "hotspot area" = "tomato",
      "outer limit"  = "goldenrod")) +
  labs(
    title = "Global Biodiversity Hotspots (2016)",
    subtitle = "Hotspots over a Natural Earth basemap",
    fill = NULL) +
  theme_Publication_map()

hotspots_map


ggsave(
  filename = "biodiversity_hotspots_map.png",
  plot = hotspots_map,
  width = 10,
  height = 6,
  units = "in",
  dpi = 300)


# End of session 2
