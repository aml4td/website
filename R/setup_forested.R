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
key <- readLines("R/census_api_key.txt")
census_api_key(key)

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

# ------------------------------------------------------------------------------
# Conduct the initial split using block sampling and buffering

set.seed(318)
forested_sf_split <-
  spatial_initial_split(
    forested_sf,
    prop = 1 / 5,
    spatial_block_cv,
    buffer = 80 * 80,
    method = "continuous",
    n = 25,
    square = FALSE
  )

forested_sf_split

forested_sf_train <- training(forested_sf_split)
forested_sf_test <- testing(forested_sf_split)

# ------------------------------------------------------------------------------
# Make non-sf versions plus an initial split object that can be used with last_fit()

# Non-sf objects
forested_train <- re_geocode(forested_sf_train)
forested_test <- re_geocode(forested_sf_test)
forested_both <- bind_rows(forested_train, forested_test)

forested_split <- make_splits(
  x = list(analysis = 1:nrow(forested_train),
           assessment = (nrow(forested_train) + 1):nrow(forested_both)),
  data = forested_both
)

# To make it look like an object produced by initial_split
class(forested_split) <- c("initial_split", class(forested_split))
forested_split

all.equal(forested_train, training(forested_split))
all.equal(forested_test, testing(forested_split))

# ------------------------------------------------------------------------------
# Make a data frame to use for plotting

plot_initial_split <- 
  forested_sf_split$data |> re_geocode() |> 
  mutate(group = "buffer", group_col = "#000000")

plot_initial_split$group[forested_sf_split$in_id] <- "training"
plot_initial_split$group_col[forested_sf_split$in_id] <- "#E7298A"

plot_initial_split$group[forested_sf_split$out_id] <- "testing"
plot_initial_split$group_col[forested_sf_split$out_id] <- "#7570B3"

if (rlang::is_installed("leaflet") & interactive()) {
  library(leaflet)
  leaflet() %>%
    addProviderTiles(providers$CartoDB.PositronNoLabels) %>%
    addCircles(
      data = plot_initial_split,
      lng = ~longitude,
      lat = ~latitude,
      color = ~group_col,
      fillColor = ~group_col,
      fill = TRUE,
      opacity = .01,
      fillOpacity = 1 / 2,
      radius = 1500,
      popup = htmltools::htmlEscape(plot_initial_split$group)
    ) |> 
    addScaleBar()
}

# ------------------------------------------------------------------------------
# Resample the training set

set.seed(670)
forested_sf_rs <- spatial_block_cv(
  forested_sf_train,
  v = 10,
  buffer = 80 * 80,
  method = "continuous",
  n = 25,
  square = FALSE
)

forested_sf_rs

# ------------------------------------------------------------------------------

forested_rs <- forested_sf_rs
forested_rs$splits <- map(forested_rs$splits, no_geometry)
map_int(forested_rs$splits, ~ nrow(analysis(.x)))
map_int(forested_rs$splits, ~ nrow(assessment(.x)))

# ------------------------------------------------------------------------------
# Make map for a single cv iteration

split_1 <- forested_rs$splits[[1]]

plot_first_fold <- 
  split_1$data |> 
  mutate(group = "buffer", group_col = "#000000")

plot_first_fold$group[split_1$in_id] <- "analysis"
plot_first_fold$group_col[split_1$in_id] <- "#E7298A"

plot_first_fold$group[split_1$out_id] <- "assessment"
plot_first_fold$group_col[split_1$out_id] <- "#7570B3"

if (rlang::is_installed("leaflet") & interactive()) {
  leaflet() %>%
    addProviderTiles(providers$CartoDB.PositronNoLabels) %>%
    addCircles(
      data = plot_first_fold,
      lng = ~longitude,
      lat = ~latitude,
      color = ~group_col,
      fillColor = ~group_col,
      fill = TRUE,
      opacity = .01,
      fillOpacity = 3 / 4,
      radius = 1500,
      popup = htmltools::htmlEscape(plot_first_fold$group)
    ) |> 
    addScaleBar()
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
  forested_split,
  forested_train,
  forested_test,
  forested_rs,
  name_key, 
  name_list,
  file = "forested_data.RData"
)
save(
  plot_initial_split,
  plot_first_fold,
  file = "forested_split_info.RData"
)
save(forested_sf, forested_sf_split, forested_sf_rs, 
     file = "forested_sf_all.RData")

# ------------------------------------------------------------------------------
# Session versions

sessioninfo::session_info()

if (!interactive()) {
  q("no")
}
