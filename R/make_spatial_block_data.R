library(forested)
library(tidymodels)
library(patchwork)
library(sf)

num_values <- 65
cell_size <- c(3, 3)
buff_size <- 1.9
seed_ind <- 4000

# ------------------------------------------------------------------------------
# Convert the lon/lat to sf geometry format

forested_sf <-
  forested %>%
  st_as_sf(coords = c("lon","lat"))

# ------------------------------------------------------------------------------
# Pick a random point as a center point

center_point <- forested_sf %>% slice(seed_ind)
other_points <- forested_sf %>% slice(-seed_ind)

# ------------------------------------------------------------------------------
# Find points near the center

dists <- st_distance(center_point, other_points)[1, ]
dist_ord <- order(dists)
sel_points <- other_points[dist_ord <= num_values,]

# ------------------------------------------------------------------------------
# Make grids and an example buffer

sel_grid <- st_make_grid(sel_points, square = FALSE, cellsize = cell_size)
sel_grid_centroid <-
  st_make_grid(sel_points,
               square = FALSE,
               cellsize = cell_size,
               what = "centers")

# ------------------------------------------------------------------------------
# Label the polygons for coloring

hex_data <- NULL
set.seed(1)
hex_groups <- LETTERS #sample(LETTERS)
for (cell in 1:length(sel_grid)) {
  cell_data <- 
    st_filter(sel_points, sel_grid[cell]) %>% 
    mutate(hex = hex_groups[cell], cell = cell)
  
  if (nrow(cell_data) > 0) {
    hex_data <- bind_rows(hex_data, cell_data)
  }
}

sel_buff <-  st_buffer(sel_grid_centroid[median(hex_data$cell)], buff_size)

# ------------------------------------------------------------------------------

save(hex_data, sel_grid, sel_buff, file = "RData/forested_plot_sf.RData")

# ------------------------------------------------------------------------------
# Session versions

sessioninfo::session_info()

if ( !interactive() ) {
  q("no")
}



