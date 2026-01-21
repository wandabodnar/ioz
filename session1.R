## ---------------------------------------------
## Session 1 — Creating and loading spatial data
## ---------------------------------------------
## Goals:
## 1) Load tabular + spatial files 
## 2) Understand geometry columns
## 3) Check / align CRS across layers
## 4) Combine layers in one map
## 5) Explore projection choices
## 6) Extra: convert to GeoJSON


# Load libraries and data
setwd("~/GIS plan/Data")

library(tidyverse)   # data handling
library(sf)          # spatial data
library(ggplot2)     # plotting
library(patchwork)   # combining plots
library(rnaturalearth) # example world maps

## --------------------
## CSV → sf (points)
## --------------------

# read CSV (non-spatial table)
point_csv <- read_csv("point.csv")
glimpse(point_csv)

# convert to spatial data, R creates a geometry column (A simple features (sf) object is a table with a geometry column.)
point_csv_sf <- st_as_sf(
  point_csv,
  coords = c("lon", "lat"),
  crs = 4326)

glimpse(point_csv_sf)

# visual checks
plot(st_geometry(point_csv_sf))

ggplot() + # grammar of graphics
  geom_sf(data = point_csv_sf) # simple features, pulls lat/long directly from the geometry column 


## --------------------
## GeoJSON → sf (lines)
## --------------------

line_geojson_sf <- st_read("line.geojson")
glimpse(line_geojson_sf) # already has geometry column

plot(st_geometry(line_geojson_sf))

ggplot() +
  geom_sf(data = line_geojson_sf)


## -------------------------
## Shapefile → sf (polygons)
## -------------------------

polygon_shp_sf <- st_read("layers/POLYGON.shp") # already has geometry column
glimpse(polygon_shp_sf)

plot(st_geometry(polygon_shp_sf))

ggplot() +
  geom_sf(data = polygon_shp_sf) +
  theme_minimal()


## ----------
## CRS check
## ----------

# All layers must be in the same CRS
st_crs(point_csv_sf)
st_crs(line_geojson_sf)
st_crs(polygon_shp_sf)


## -------------------
## Combine all layers
## -------------------

ggplot() +
  geom_sf(data = polygon_shp_sf, fill = "lightgrey") +
  geom_sf(data = line_geojson_sf, colour = "blue") +
  geom_sf(data = point_csv_sf, colour = "red") +
  theme_minimal()


## -----------------------------
## Projection examples - Global
## -----------------------------

world <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf")

# Mercator projection: shows directions as straight lines, but it severely distorts the size of landmasses, especially near the poles
ggplot(world) +
  geom_sf() +
  coord_sf(crs = st_crs(3857)) +        # EPSG code is a unique identifier used to represent coordinate systems
  ggtitle("Web Mercator (EPSG:3857)") +
  theme_minimal()

# Robinson projection: visually appealing for general use, though it distorts size, shape, and distance, especially near the poles
ggplot(world) +
  geom_sf() +
  coord_sf(crs = "+proj=robin") +
  ggtitle("Robinson projection") +
  theme_minimal()

# Mollweide projection: it accurately shows the relative size of landmasses, but it heavily distorts shapes and angles, especially near the edges
ggplot(world) +
  geom_sf() +
  coord_sf(crs = "+proj=moll") +
  ggtitle("Mollweide projection") +
  theme_minimal()

# WGS84 (lon/lat): a variant of the Mercator map projection and is the de facto standard for Web mapping applications
ggplot(world) +
  geom_sf() +
  coord_sf(crs = st_crs(4326)) +
  ggtitle("WGS84 (EPSG:4326) — lon/lat") +
  theme_minimal()


## ----------------------------------------------
## Equal-area (or equivalent) projection examples
## ----------------------------------------------

ggplot(world) +
  geom_sf() +
  coord_sf(crs = st_crs(8857)) +
  ggtitle("World Map (Equal Earth - EPSG:8857)") +
  theme_minimal()

# Filter to Europe
europe_data <- world %>% # pipe operator chains functions together, |> also works in R 4.1+
  filter(continent == "Europe")

ggplot(europe_data) +
  geom_sf() +
  coord_sf(crs = st_crs(3035), 
           xlim = c(-15, 45), 
           ylim = c(33, 70), 
           default_crs = st_crs(4326)) +
  ggtitle("Europe (ETRS89 / LAEA Europe - EPSG:3035)") +
  theme_minimal()

# Filter to Antarctica
antarctica_data <- world %>%
  filter(name == "Antarctica")

ggplot(antarctica_data) +
  geom_sf() +
  coord_sf(crs = st_crs(3031)) +
  ggtitle("Antarctica (Lambert Azimuthal Equal-Area - EPSG:3031)") +
  theme_minimal()


## --------------------------
## Extra: convert to GeoJSON
## --------------------------


## Shapefile to GeoJSON

point_shp_sf <- st_read("layers/POINT.shp")   # already has geometry column

# write GeoJSON
st_write(
  point_shp_sf,
  "layers/point_shp.geojson",
  driver = "GeoJSON",
  delete_dsn = TRUE)

# write GeoJSON
st_write(
  point_csv_sf,
  "layers/point_csv.geojson",
  driver = "GeoJSON",
  delete_dsn = TRUE)


# End of session 1
