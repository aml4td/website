library(tidymodels)
library(rules)
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

c5_spec <-
  boost_tree(
    mode = "classification",
    trees = tune(),
    min_n = tune()
  ) |>
  set_engine("C5.0")

c5_param <-
  c5_spec |>
  extract_parameter_set_dials() |>
  update(trees = trees(c(5, 100)))


set.seed(498)
forest_c5_res <-
  c5_spec |>
  tune_grid(
    class ~ .,
    resamples = forested_rs,
    grid = 25,
    param_info = c5_param,
    control = control_grid(
      save_pred = TRUE,
      save_workflow = TRUE,
      extract = ensmbl_stats
    ),
    metrics = cls_mtr
  )

forest_c5_best <- select_best(forest_c5_res, metric = "brier_class")

forest_c5_pred <-
  forest_c5_res |>
  collect_predictions(parameters = forest_c5_best) |>
  mutate(wflow_id = "Boosted C5.0") |>
  relocate(wflow_id)

forest_c5_mtr_ex <-
  forest_c5_pred |>
  cls_mtr(class, estimate = .pred_class, .pred_Yes)

# ------------------------------------------------------------------------------

c5rules_spec <-
  C5_rules(
    mode = "classification",
    trees = tune(),
    min_n = tune()
  ) |>
  set_engine("C5.0")

c5rules_param <-
  c5rules_spec |>
  extract_parameter_set_dials() |>
  update(trees = trees(c(5, 100)))

set.seed(498)
forest_c5rules_res <-
  c5rules_spec |>
  tune_grid(
    class ~ .,
    resamples = forested_rs,
    grid = 25,
    param_info = c5rules_param,
    control = control_grid(
      save_pred = TRUE,
      save_workflow = TRUE,
      extract = ensmbl_stats
    ),
    metrics = cls_mtr
  )

forest_c5rules_best <- select_best(forest_c5rules_res, metric = "brier_class")

forest_c5rules_pred <-
  forest_c5rules_res |>
  collect_predictions(parameters = forest_c5rules_best) |>
  mutate(wflow_id = "Boosted C5.0 Rules") |>
  relocate(wflow_id)

forest_c5rules_mtr_ex <-
  forest_c5rules_pred |>
  cls_mtr(class, estimate = .pred_class, .pred_Yes)

forest_c5_set_res <-
  as_workflow_set(
    `Boosted C5.0` = forest_c5_res |> butcher::butcher(),
    `Boosted C5.0 Rules` = forest_c5rules_res |> butcher::butcher(),
  )

# ------------------------------------------------------------------------------

save(
  list = ls(pattern = "(forest_c5_)|(forest_c5rules_)"),
  file = "RData/forest_c5.RData"
)
