library(tidymodels)
library(bestNormalize)
library(modeldatatoo)
library(embed) 

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
cores <- parallel::detectCores()

# ------------------------------------------------------------------------------

source("R/setup_chemometrics.R")

# ------------------------------------------------------------------------------

umap_base <-
  recipe(barley ~ ., data = barley_train) %>%
  step_nzv(all_predictors()) %>%
  step_orderNorm(all_numeric_predictors()) %>%
  prep()

# ------------------------------------------------------------------------------

rng <- function(x, min = -1, max = 1) {
  (x - min(x)) / (max(x) - min(x)) * (max - min) + min
}

# ------------------------------------------------------------------------------
# Estimate some initial states so that any non-uniqueness does not affect the
# final embedding

set.seed(748)
pca_start <-
  umap_base %>%
  step_pca(all_numeric_predictors(), num_comp = 2) %>%
  step_range(starts_with("PC"), min = -10, max = 10) %>%
  prep() %>%
  bake(new_data = NULL, starts_with("PC")) %>%
  as.matrix() %>%
  scale()

set.seed(156)
spectral_start <-
  umap_base %>%
  step_umap(
    all_numeric_predictors(),
    num_comp = 2,
    epochs = 0 # <- this gives us the spectral embedding
  ) %>%
  step_range(starts_with("UMAP"), min = -10, max = 10) %>%
  prep() %>%
  bake(new_data = NULL, starts_with("UMAP")) %>%
  as.matrix() %>%
  scale()

set.seed(984)
random_start <-
  matrix(runif(2 * nrow(barley_train), min = -10, max = 10), ncol = 2)

# ------------------------------------------------------------------------------

initial_state <- c("spectral", "pca", "random")
neighbors <- c(5, 15, 25, 35, 45)
min_dist <- (0:5) / 5
learn_rate <- 1
supervised <- (0:7) / 10

umap_grid <-
  crossing(initial_state, neighbors, min_dist, learn_rate, supervised) %>%
  mutate(.config = row_number())

set.seed(101)
umap_grid <- umap_grid[sample(umap_grid$.config),]
nrow(umap_grid)

# ------------------------------------------------------------------------------

verbose <- TRUE
time_start <- proc.time()[3]

umap_results <- NULL
for (j in 1:nrow(umap_grid)) {
  if (j %% 10 == 0 & verbose) {
    time_now <- proc.time()[3]
    tmp_dur <- (time_now - time_start) / 60
    cat(sprintf("%2.0f", j), " (", sprintf("%5.1f", tmp_dur), "m)\n", sep = "")
  }

  if (umap_grid$supervised[j] > 0) {
    umap_y <- vars(barley)
  } else {
    umap_y <- NULL
  }

  if (umap_grid$initial_state[j] == "spectral") {
    init_mat <- spectral_start
  } else if (umap_grid$initial_state[j] == "random") {
    init_mat <- random_start
  } else {
    init_mat <- pca_start
  }

  set.seed(453)
  umap_rec <-
    umap_base %>%
    step_umap(
      all_numeric_predictors(),
      outcome = umap_y,
      num_comp = 2,
      epochs = 1000,
      neighbors = umap_grid$neighbors[j],
      min_dist = umap_grid$min_dist[j],
      learn_rate = umap_grid$learn_rate[j],
      target_weight = umap_grid$supervised[j],
      options = list(init = init_mat, verbose = FALSE, n_threads = cores)
    ) %>%
    prep()

  umap_dat <-
    umap_rec %>%
    bake(new_data = barley_val, barley, starts_with("UMAP")) %>%
    mutate(
      UMAP1 = rng(UMAP1),
      UMAP2 = rng(UMAP2)
    ) %>%
    bind_cols(barley_val %>% select(wvlgth_100, wvlgth_500)) %>%
    mutate(
      neighbors = umap_grid$neighbors[j],
      min_dist = umap_grid$min_dist[j],
      learn_rate = umap_grid$learn_rate[j],
      initial  = umap_grid$initial_state[j],
      supervised = umap_grid$supervised[j],
      .config = umap_grid$.config[j]
    )

  umap_results <- bind_rows(umap_results, umap_dat)
  rm(umap_dat)

  if (j == nrow(umap_grid) & verbose) {
    time_now <- proc.time()[3]
    tmp_dur <- (time_now - time_start) / 60
    cat(sprintf("%2.0f", j), " (", sprintf("%5.1f", tmp_dur), "m)\n", sep = "")
    cat("\n\n")
  }

}

time_end <- proc.time()[3]

# ------------------------------------------------------------------------------

save(
  umap_results,
  file = "RData/umap_weight_results.RData",
  compress = TRUE)

