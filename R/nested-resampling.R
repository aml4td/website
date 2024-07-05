library(tidymodels)
library(finetune)
# pak::pak(c("tidymodels/finetune@nested"), ask = FALSE)
if ( packageVersion("finetune") < "1.2.0.9000" ) {
  cli::cli_abort("Please load the devel branch of finetune using \\
                 {.code pak::pak('tidymodels/finetune@nested')}")
}
library(doMC)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
registerDoMC(cores = parallel::detectCores())

# ------------------------------------------------------------------------------

source("R/setup_two_class_example.R")

# ------------------------------------------------------------------------------

knn_prm <- parameters(neighbors(c(2, 50)), dist_power())

knn_reg <-
  grid_regular(knn_prm, levels = c(5, 3)) %>%
  mutate(grid = "Regular")

sfd_size <- nrow(knn_reg)

knn_sfd <- 
  grid_space_filling(knn_prm, size = sfd_size) %>%
  mutate(grid = "Space-Filling")

knn_spec <- 
  nearest_neighbor(neighbors = tune(), dist_power = tune(), 
                   weight_func = "rectangular") %>% 
  set_mode("classification")

knn_wflow <-
  workflow() %>%
  add_model(knn_spec) %>%
  add_formula(class ~ A + B)

# ------------------------------------------------------------------------------
library(rlang)

knn_sfd_nest_time <- 
  system.time({
    set.seed(1)
    knn_sfd_nest_res <-
      knn_wflow %>%
      tune_nested(
        resamples = sim_nested_rs,
        metrics = metric_set(brier_class),
        grid = knn_sfd %>% select(-grid)
      )
  })

# ------------------------------------------------------------------------------

large_grid <- grid_space_filling(knn_prm, size = 100)

large_nest_race_time <- 
  system.time({
    set.seed(1)
    knn_race_nest_res <-
      knn_wflow %>%
      tune_nested(
        resamples = sim_nested_rs,
        metrics = metric_set(brier_class),
        fn = "tune_race_anova",
        grid = large_grid
      )
  })

# ------------------------------------------------------------------------------

save(knn_sfd_nest_res, knn_race_nest_res, 
     knn_sfd_nest_time, large_nest_race_time, 
     file = "RData/nested_res.RData")

# ------------------------------------------------------------------------------

if ( !interactive() ) {
  q("no")
}
