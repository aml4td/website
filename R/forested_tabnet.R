library(tidymodels)
library(bonsai)
library(spatialsample)
library(mirai)
library(tabnet)

# ------------------------------------------------------------------------------

# daemons(parallel::detectCores())
load("RData/forested_data.RData")
cls_mtr <- metric_set(brier_class, roc_auc, pr_auc, mn_log_loss)

# ------------------------------------------------------------------------------

tbnt_rec <- 
  recipe(class ~ ., data = forested_train) |> 
  step_normalize(all_numeric_predictors())

tbnt_spec <- 
  tabnet(
    mode = "classification",
    # cat_emb_dim = NULL,
    decision_width = tune(),
    attention_width = tune(),
    num_steps = tune(),
    # mask_type = tune(),
    # num_independent = NULL,
    # num_shared = NULL,
    # num_independent_decoder = NULL,
    # num_shared_decoder = NULL,
    penalty = tune(),
    momentum = tune(),
    epochs = 1000L,
    batch_size = tune(),
    # virtual_batch_size = NULL,
    learn_rate = tune(),
    lr_scheduler = "reduce_on_plateau",
    verbose = TRUE,
    skip_importance = TRUE
  ) |> 
  set_engine("torch", num_workers = 10) # , device = "mps"

tbnt_param <- 
  tbnt_spec |> 
  extract_parameter_set_dials() |> 
  update(
    learn_rate = learn_rate(c(-4, -1/2)),
    batch_size = batch_size(c(5, 9)),
    momentum = momentum(c(0.01, 0.4))
  )

# ------------------------------------------------------------------------------

system.time({
set.seed(458)
forest_tbnt_res <-
  tbnt_spec |>
  tune_grid(
    tbnt_rec,
    resamples = forested_rs,
    grid = 25,
    param_info = tbnt_param, 
    control = control_grid(
      save_pred = TRUE,
      save_workflow = TRUE,
      verbose = TRUE
    ),
    metrics = cls_mtr
  )
})

show_best(forest_tbnt_res, metric = "brier_class")

# ------------------------------------------------------------------------------

forest_tbnt_best <- select_best(forest_tbnt_res, metric = "brier_class")

forest_tbnt_pred <-
  forest_tbnt_res |>
  collect_predictions(parameters = forest_tbnt_best) |>
  mutate(wflow_id = "TabNet") |>
  relocate(wflow_id)

forest_tbnt_mtr_ex <-
  forest_tbnt_pred |>
  cls_mtr(class, estimate = .pred_class, .pred_Yes)

forest_tbnt_set_res <-
  as_workflow_set(
    TabNet = forest_tbnt_res |> butcher::butcher(),
  )

# ------------------------------------------------------------------------------

save(list = ls(pattern = "forest_tbnt_"), 
     file = "RData/forest_tabnet.RData")

