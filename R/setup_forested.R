library(sf)
library(tidymodels)
library(spatialsample)
library(tidysdm)
library(forested)
library(tidycensus)
library(cli)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(
  pillar.advice = FALSE,
  pillar.min_title_chars = Inf,
  future.rng.onMisuse = "ignore"
)
# Read in api key; in .gitignore
key <- readLines("census_api_key.txt")

# ------------------------------------------------------------------------------
# To re-calculate geocodes and strip off geometry column

re_geocode <- function(x) {
  x$longitude <- sf::st_coordinates(x)[, 1]
  x$latitude <- sf::st_coordinates(x)[, 2]
  st_drop_geometry(x)
}

no_geometry <- function(split) {
  dat <- re_geocode(split$data)
  split$data <- dat
  split
}

# ------------------------------------------------------------------------------

# These computations take a while so we do them in batch mode then load the
# results in later chapters

# ------------------------------------------------------------------------------
# We remove some of the existing algorithmic data already there.

for_analysis <-
  forested |>
  rename(class = forested) |>
  select(-tree_no_tree, -land_type, -canopy_cover) |>
  rename(longitude = lon, latitude = lat)

forested_names <- names(for_analysis)

# ------------------------------------------------------------------------------
# Convert the longitude/latitude to sf geometry format

forested_sf <-
  for_analysis |>
  st_as_sf(coords = c("longitude", "latitude"), crs = st_crs("EPSG:4326"))

# ------------------------------------------------------------------------------
# Get county data

WA_acs <- get_acs(
  state = "WA",
  geography = "tract",
  variables = "B19013_001",
  geometry = TRUE
)
WA_acs <- st_transform(WA_acs, 4326) |>
  select(-variable, -estimate, -moe)

forested_sf <- forested_sf |>
  st_join(WA_acs) |>
  mutate(
    split_up = map(NAME, ~ strsplit(.x, ";")[[1]]),
    county = map_chr(split_up, ~ .x[2]),
    county = map_chr(county, ~ gsub(" County", "", .x)),
    county = map_chr(county, ~ trimws(tolower(.x))),
    county = map_chr(county, ~ gsub(" ", "_", .x)),
    county = factor(county)
  ) |>
  select(-GEOID, -NAME, -split_up)

cli::cli_alert(
  "We'll have to remove {sum(is.na(forested_sf$county))} location{?s} from the \\
  data due to missing county information."
)

forested_sf <- forested_sf |>
  filter(!is.na(county))

forested_df <- re_geocode(forested_sf)

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
  for_analysis |>
  add_rowindex() |>
  full_join(split_groups, by = ".row") |>
  mutate(
    group_col = if_else(group == "training", "#E7298A", "#7570B3"),
    group_col = if_else(group == "buffer", "#000000", group_col)
  )

if (rlang::is_installed("leaflet") & interactive()) {
  library(leaflet)
  leaflet() %>%
    addProviderTiles(providers$CartoDB.PositronNoLabels) %>%
    addCircles(
      data = forested_split_info,
      lng = ~longitude,
      lat = ~latitude,
      color = ~group_col,
      fillColor = ~group_col,
      fill = TRUE,
      opacity = .01,
      fillOpacity = 1 / 2,
      radius = 1500,
      popup = htmltools::htmlEscape(forested_split_info$group)
    )
}

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

forested_train <- re_geocode(forested_sf_train)
forested_test <- re_geocode(forested_sf_test)
forested_rs$splits <- map(forested_rs$splits, no_geometry)

# ------------------------------------------------------------------------------
# Make map for a single cv iteration

cv_split_groups <- tibble(.row = 1:nrow(forested_sf_train), group = "buffer")
cv_split_groups$group[forested_rs$splits[[1]]$in_id] <- "analysis"
cv_split_groups$group[forested_rs$splits[[1]]$out_id] <- "assessment"

forested_cv_split_info <-
  forested_train |>
  add_rowindex() |>
  full_join(cv_split_groups, by = ".row") |>
  mutate(
    group_col = if_else(group == "analysis", "#E7298A", "#7570B3"),
    group_col = if_else(group == "buffer", "#000000", group_col)
  )

if (rlang::is_installed("leaflet") & interactive()) {
  leaflet() %>%
    addProviderTiles(providers$CartoDB.PositronNoLabels) %>%
    addCircles(
      data = forested_cv_split_info,
      lng = ~longitude,
      lat = ~latitude,
      color = ~group_col,
      fillColor = ~group_col,
      fill = TRUE,
      opacity = .01,
      fillOpacity = 3 / 4,
      radius = 1500,
      popup = htmltools::htmlEscape(forested_cv_split_info$group)
    )
}

# ------------------------------------------------------------------------------
# translations

name_key <- 
  tribble(
    ~text, ~variable,
    "dew temperature", "dew_temp",
    "annual precipitation", "precip_annual",
    "annual minimum temperature", "temp_annual_min",
    "annual maximum temperature", "temp_annual_max",
    "january minimum temperature", "temp_january_min",
    "annual mean temperature", "temp_annual_mean",
    "minimum vapor", "vapor_min",
    "maximum vapor", "vapor_max"
  )

name_list <- 
  list(
    `dew temperature` = "dew_temp",
    `annual precipitation` = "precip_annual",
    `annual minimum temperature` = "temp_annual_min",
    `annual maximum temperature` = "temp_annual_max",
    `january minimum temperature` = "temp_january_min",
    `annual mean temperature` = "temp_annual_mean",
    `minimum vapor` = "vapor_min",
    `maximum vapor` = "vapor_max"
  )

# ------------------------------------------------------------------------------
# Save various things

save(
  forested_train,
  forested_test,
  forested_rs,
  name_key, 
  name_list,
  file = "forested_data.RData"
)
save(
  forested_split_info,
  forested_cv_split_info,
  file = "forested_split_info.RData"
)
save(forested_sf, forested_df, file = "forested_all.RData")

# ------------------------------------------------------------------------------
# Session versions

sessioninfo::session_info()

if (!interactive()) {
  q("no")
}
