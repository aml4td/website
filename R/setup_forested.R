library(sf)
library(tidymodels)
library(spatialsample)
library(tidysdm)
library(forested)
# library(zipcodeR)
library(furrr)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(
  pillar.advice = FALSE,
  pillar.min_title_chars = Inf,
  future.rng.onMisuse = "ignore"
)

plan("multisession")

# ------------------------------------------------------------------------------

# These computations take a while so we do them in batch mode then load the
# results in later chapters

# ------------------------------------------------------------------------------
# We remove some of the existing algorithmic data already there.

for_analysis <-
  forested %>%
  rename(class = forested) %>%
  select(-tree_no_tree, -land_type, -canopy_cover) |>
  rename(
    dew_temperature = dew_temp,
    annual_precipitation = precip_annual,
    annual_minimum_temperature = temp_annual_min,
    annual_maximum_temperature = temp_annual_max,
    january_minimum_temperature = temp_january_min,
    annual_mean_temperature = temp_annual_mean,
    minimum_vapor = vapor_min,
    maximum_vapor = vapor_max,
    longitude = lon,
    latitude = lat
  )

# ------------------------------------------------------------------------------
# Get ZIP codes
# 
# zip_codes <- 
#   future_map(
#     1:nrow(for_analysis),
#     ~ search_radius(
#       lat = for_analysis$latitude[.x], 
#       lng = for_analysis$longitude[.x], 
#       radius = 200
#     ) %>% 
#       mutate(.row = .x)
#   )
# 
# has_zip <- map_lgl(zip_codes, ~ nrow(.x) > 0)
# any(!has_zip)
# 
# zip_estimates <- 
#   map_dfr(
#     zip_codes,
#     ~ slice_min(.x, distance, n = 1, with_ties = FALSE, by = c(.row))
#   ) %>% 
#   arrange(.row) %>% 
#   select(zip = zipcode)

# for_analysis <- 
#   bind_cols(for_analysis, zip_estimates) %>% 
#   mutate(zip = factor(zip))

# ------------------------------------------------------------------------------
# Convert the lon/lat to sf geometry format

forested_sf <-
  for_analysis %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = st_crs("EPSG:4326"))

# ------------------------------------------------------------------------------
# Conduct the initial split using block sampling and buffering

set.seed(318)
forested_split <-
  spatial_initial_split(
    forested_sf,
    prop = 1 / 5,
    spatial_block_cv,
    buffer = 80 * 80,
    method = "continuous",
    n = 25,
    square = FALSE
  )

forested_sf_train <- training(forested_split)
forested_sf_test <- testing(forested_split)

# ------------------------------------------------------------------------------
# Make a data frame to use for plotting

split_groups <- tibble(.row = 1:nrow(forested_sf), group = "buffer")
split_groups$group[forested_split$in_id] <- "training"
split_groups$group[forested_split$out_id] <- "testing"

forested_split_info <-
  for_analysis %>%
  add_rowindex() %>%
  full_join(split_groups, by = ".row") %>%
  mutate(
    group_col = if_else(group == "training", "#E7298A", "#7570B3"),
    group_col = if_else(group == "buffer", "#000000", group_col)
  )

# ------------------------------------------------------------------------------
# Resample the training set

set.seed(670)
forested_rs <- spatial_block_cv(
  forested_sf_train,
  v = 10,
  buffer = 80 * 80,
  method = "continuous",
  n = 25,
  square = FALSE
)

# ------------------------------------------------------------------------------
# re-calculate geocodes and strip off geometry column

re_geocode <- function(x) {
  x %>%
    dplyr::mutate(
      longitude = sf::st_coordinates(.)[, 1],
      latitude = sf::st_coordinates(.)[, 2]
    ) %>%
    st_drop_geometry()
}

no_geometry <- function(split) {
  dat <- re_geocode(split$data)
  split$data <- dat
  split
}

forested_train <- re_geocode(forested_sf_train)
forested_test <- re_geocode(forested_sf_test)
forested_rs$splits <- map(forested_rs$splits, no_geometry)

# ------------------------------------------------------------------------------
# Make map for a single cv iteration

cv_split_groups <- tibble(.row = 1:nrow(forested_sf_train), group = "buffer")
cv_split_groups$group[forested_rs$splits[[1]]$in_id] <- "analysis"
cv_split_groups$group[forested_rs$splits[[1]]$out_id] <- "assessment"

forested_cv_split_info <-
  forested_train %>%
  add_rowindex() %>%
  full_join(cv_split_groups, by = ".row") %>%
  mutate(
    group_col = if_else(group == "analysis", "#E7298A", "#7570B3"),
    group_col = if_else(group == "buffer", "#000000", group_col)
  )

# ------------------------------------------------------------------------------
# Save various things

save(
  forested_train,
  forested_test,
  forested_rs,
  file = "forested_data.RData"
)
save(
  forested_split_info,
  forested_cv_split_info,
  file = "forested_split_info.RData"
)
save(forested_sf, file = "forested_sf.RData")

# ------------------------------------------------------------------------------
# Session versions

sessioninfo::session_info()

if (!interactive()) {
  q("no")
}
