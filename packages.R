# List packages
pkgs <- c(
  "esri2sf", "ggplot2", "ggspatial", "ggthemes", "leafem",
  "leaflet", "leaflet.extras", "leaflet.extras2", "leaflet.providers",
  "patchwork", "rnaturalearth", "sf", "stars", "tidyverse"
)

# Install any missing packages
to_install <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(to_install) > 0) install.packages(to_install)

# Load them all
invisible(lapply(pkgs, library, character.only = TRUE))
