library(tidymodels)
library(bonsai)
library(spatialsample)
library(mirai)


# ------------------------------------------------------------------------------

daemons(5)
load("RData/forested_data.RData")
cls_mtr <- metric_set(brier_class, roc_auc, pr_auc, mn_log_loss)

# ------------------------------------------------------------------------------

ensmbl_stats <- function(x) {
  require(tidymodels)
  require(lorax)
  if (inherits(x, c("model_fit", "workflow"))) {
    x <- extract_fit_engine(x)
  } else {
    dat <- NULL
  }
  num_members <- num_ensemble_members(x)
  mem_seq <- seq_len(num_members)

  rule_df <- extract_rules(
    x,
    tree = mem_seq,
    add_statistics = TRUE
  )

  rule_df |>
    summarize(
      num_rule_terms = mean(num_rule_terms),
      num_rule_predictors = mean(num_rule_predictors),
      num_terminal_nodes = length(tree)
    ) |>
    mutate(num_members = num_members)
}

# ------------------------------------------------------------------------------

xgb_spec <-
  boost_tree(
    mode = "classification",
    trees = 5000,
    mtry = tune(),
    min_n = tune(),
    tree_depth = tune(),
    loss_reduction = tune(),
    learn_rate = tune(),
    stop_iter = 5
  )

xgb_param <-
  xgb_spec |>
  extract_parameter_set_dials() |>
  update(tree_depth = tree_depth(c(2, 32)))

set.seed(458)
forest_xgb_res <-
  xgb_spec |>
  tune_grid(
    class ~ .,
    resamples = forested_rs,
    grid = 25,
    param_info = xgb_param,
    control = control_grid(
      save_pred = TRUE,
      save_workflow = TRUE,
      extract = ensmbl_stats
    ),
    metrics = cls_mtr
  )

forest_xgb_best <- select_best(forest_xgb_res, metric = "brier_class")

forest_xgb_pred <-
  forest_xgb_res |>
  collect_predictions(parameters = forest_xgb_best) |>
  mutate(wflow_id = "XGBoost") |>
  relocate(wflow_id)

forest_xgb_mtr_ex <-
  forest_xgb_pred |>
  cls_mtr(class, estimate = .pred_class, .pred_Yes)

forest_xgb_set_res <-
  as_workflow_set(
    XGBoost = forest_xgb_res |> butcher::butcher(),
  )

# ------------------------------------------------------------------------------

save(list = ls(pattern = "forest_xgb_"), file = "RData/forest_xgboost.RData")

if (!interactive()) {
  q("no")
}
