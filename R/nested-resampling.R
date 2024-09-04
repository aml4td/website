library(tidymodels)
library(bonsai)
library(finetune)
# pak::pak(c("tidymodels/finetune@nested"), ask = FALSE)
if ( packageVersion("finetune") < "1.2.0.9000" ) {
  cli::cli_abort("Please load the devel branch of finetune using \\
                 {.code pak::pak('tidymodels/finetune@nested')}")
}
library(future)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

plan(multisession)
num_workers <- parallel::detectCores()

# ------------------------------------------------------------------------------

source("~/github/website/R/setup_two_class_example.R")

set.seed(943)
sim_tr <- sim_logistic(2000, sim_f)

set.seed(14)
sim_rs <- vfold_cv(sim_tr)

set.seed(14)
sim_nested_rs <- nested_cv(sim_tr, outside = vfold_cv(), inside = vfold_cv())

# ------------------------------------------------------------------------------

one_dim_spec <- 
  boost_tree(learn_rate = tune(), trees = 500) %>% 
  set_mode("classification") %>% 
  set_engine("lightgbm")

one_dim_wflow <-
  workflow() %>%
  add_model(one_dim_spec) %>%
  add_formula(class ~ A + B)

one_dim_param <- 
  one_dim_wflow %>% 
  extract_parameter_set_dials() %>% 
  update(learn_rate = learn_rate(c(-3, -1)))

one_dim_reg <- grid_regular(one_dim_param, levels = 100) 

# ------------------------------------------------------------------------------

grid_time <- 
  system.time({
    set.seed(1)
    grid_res <-
      one_dim_wflow %>%
      tune_grid(
        resamples = sim_rs,
        metrics = metric_set(brier_class),
        grid = one_dim_reg
      )
  })

grid_nest_time <- 
  system.time({
    set.seed(1)
    nest_grid_res <-
      one_dim_wflow %>%
      tune_nested(
        resamples = sim_nested_rs,
        metrics = metric_set(brier_class),
        grid = one_dim_reg
      )
  })

bo_time <- 
  system.time({
    set.seed(1)
    bo_res <-
      one_dim_wflow %>%
      tune_bayes(
        resamples = sim_rs,
        metrics = metric_set(brier_class),
        initial = 3, 
        iter = 10,
        param_info = one_dim_param
      ) 
  })

bo_nest_time <- 
  system.time({
    set.seed(1)
    nest_bo_res <-
      one_dim_wflow %>%
      tune_nested(
        resamples = sim_nested_rs,
        metrics = metric_set(brier_class),
        fn = "tune_bayes",
        initial = 3, 
        iter = 20,
        param_info = one_dim_param
      )
  })

# ------------------------------------------------------------------------------

debiased_grid <- debias_estimate(grid_res)
debiased_bo <- debias_estimate(bo_res)

# ------------------------------------------------------------------------------

save(list = c(ls(pattern = "_res$"), ls(pattern = "_time$"), 
              "debiased_grid", "debiased_bo", "num_workers"),
     file = "~/github/website/RData/nested_res.RData")

# ------------------------------------------------------------------------------

if ( !interactive() ) {
  q("no")
}
