library(tidymodels)
library(bonsai)
library(spatialsample)
library(mirai)

if (!rlang::is_installed("catboost")) {
  # See https://catboost.ai/docs/en/installation/r-installation-binary-installation
  
  version <- "1.2.7"
  template <- "https://github.com/catboost/catboost/releases/download/v{version}/catboost-R-darwin-universal2-{version}.tgz"
  
  target_url <- glue::glue(template)
  target_dest <- tempfile()
  download.file(target_url, target_dest)
  
  inst <- glue::glue("R CMD INSTALL  --no-staged-install {target_dest}")
  
  # Deep breath
  system(inst) 
}

# ------------------------------------------------------------------------------

daemons(parallel::detectCores())
load("RData/forested_data.RData")
cls_mtr <- metric_set(brier_class, roc_auc, pr_auc, mn_log_loss)

# ------------------------------------------------------------------------------

ctb_spec <-
  boost_tree(
    mode = "classification",
    trees = tune(),
    mtry = tune(),
    tree_depth = tune(),
    learn_rate = tune()
  ) |> 
  set_engine("lightgbm")

ctb_param <- 
  ctb_spec |> 
  extract_parameter_set_dials() |> 
  update(
    tree_depth = tree_depth(c(2, 32))
    )

set.seed(458)
forest_ctb_res <-
  ctb_spec |>
  tune_grid(
    class ~ .,
    resamples = forested_rs,
    grid = 25,
    param_info = ctb_param,
    control = control_grid(
      save_pred = TRUE,
      save_workflow = TRUE
    ),
    metrics = cls_mtr
  )

forest_ctb_best <- select_best(forest_ctb_res, metric = "brier_class")

forest_ctb_pred <-
  forest_ctb_res |>
  collect_predictions(parameters = forest_ctb_best) |>
  mutate(wflow_id = "LightGBM") |>
  relocate(wflow_id)

forest_ctb_mtr_ex <-
  forest_ctb_pred |>
  cls_mtr(class, estimate = .pred_class, .pred_Yes)

forest_ctb_set_res <-
  as_workflow_set(
    CatBoost = forest_ctb_res |> butcher::butcher(),
  )

# ------------------------------------------------------------------------------

save(list = ls(pattern = "forest_ctb_"), 
     file = "RData/forest_catboost.RData")
