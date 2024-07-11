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

num_workers <- parallel::detectCores()

# ------------------------------------------------------------------------------

source("~/content/website/R/setup_two_class_example.R")

# ------------------------------------------------------------------------------

bst_spec <- 
  boost_tree(learn_rate = tune(), trees = tune()) %>% 
  set_mode("classification")

bst_wflow <-
  workflow() %>%
  add_model(bst_spec) %>%
  add_formula(class ~ A + B)

bst_param <- 
  bst_wflow %>% 
  extract_parameter_set_dials() %>% 
  update(learn_rate = learn_rate(c(-3, -1)))

bst_reg <-
  grid_regular(bst_param, levels = c(5, 3)) %>%
  mutate(grid = "Regular")

sfd_size <- nrow(bst_reg)

set.seed(nrow(bst_reg))
bst_random <-
  grid_random(bst_param, size = sfd_size) %>%
  mutate(grid = "Random")

bst_sfd <- grid_space_filling(bst_param, size = sfd_size)

large_param <- 
  bst_param %>% 
  update(trees = trees(c(1, 3000)))

large_sfd <- 
  large_param %>% 
  grid_space_filling(size = 100)

large_reg <- 
  large_param %>% 
  grid_regular(levels = 10)

# ------------------------------------------------------------------------------

sfd_seq_time <- 
  system.time({
    set.seed(1)
    tmp <-
      bst_wflow %>%
      tune_grid(
        resamples = sim_rs,
        metrics = metric_set(brier_class),
        grid = bst_sfd
      )
  })

registerDoMC(cores = num_workers)

sfd_time <- 
  system.time({
    set.seed(1)
    sfd_res <-
      bst_wflow %>%
      tune_grid(
        resamples = sim_rs,
        metrics = metric_set(brier_class),
        grid = bst_sfd
      )
  })


sfd_nest_time <- 
  system.time({
    set.seed(1)
    sfd_nest_res <-
      bst_wflow %>%
      tune_nested(
        resamples = sim_nested_rs,
        metrics = metric_set(brier_class),
        grid = bst_sfd
      )
  })

# TODO not naming an argument gets an error of :
# Caused by error in `rlang::call_modify()`:
#   ! argument "arg" is missing, with no default

# ------------------------------------------------------------------------------

large_grid_time <- 
  system.time({
    set.seed(1)
    large_grid_res <-
      bst_wflow %>%
      tune_grid(
        resamples = sim_rs,
        metrics = metric_set(brier_class),
        grid = large_sfd
      )
  })


large_grid_reg_time <- 
  system.time({
    set.seed(1)
    large_grid_reg_res <-
      bst_wflow %>%
      tune_grid(
        resamples = sim_rs,
        metrics = metric_set(brier_class),
        grid = large_reg
      )
  })


large_nest_grid_time <- 
  system.time({
    set.seed(1)
    large_nest_grid_res <-
      bst_wflow %>%
      tune_nested(
        resamples = sim_nested_rs,
        metrics = metric_set(brier_class),
        grid = large_sfd
      )
  })


large_race_time <- 
  system.time({
    set.seed(1)
    large_race_res <-
      bst_wflow %>% 
      tune_race_anova(
        resamples = sim_rs,
        metrics = metric_set(brier_class),
        grid = large_sfd,
        control = control_race(verbose_elim = FALSE)
      ) 
  })

large_nest_race_time <- 
  system.time({
    set.seed(1)
    bst_race_nest_res <-
      bst_wflow %>%
      tune_nested(
        resamples = sim_nested_rs,
        metrics = metric_set(brier_class),
        fn = "tune_race_anova",
        grid = large_sfd
      )
  })

registerDoSEQ()

large_seq_time <- 
  system.time({
    set.seed(1)
    large_race_tmp <-
      bst_wflow %>% 
      tune_race_anova(
        resamples = sim_rs,
        metrics = metric_set(brier_class),
        grid = large_sfd,
        control = control_race(verbose_elim = FALSE)
      ) 
  })

# ------------------------------------------------------------------------------

save(list = c(ls(pattern = "_res$"), ls(pattern = "_time$"), 
              "large_param", "large_sfd", "num_workers"),
     file = "~/content/website/RData/nested_res.RData")

# ------------------------------------------------------------------------------

if ( !interactive() ) {
  q("no")
}
