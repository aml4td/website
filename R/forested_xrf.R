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

xrf_spec <-
  rule_fit(
    mtry = tune(),
    trees = 50,
    min_n = tune(),
    tree_depth = tune(),
    learn_rate = tune(),
    loss_reduction = tune(),
    penalty = tune()
  ) |>
  set_mode('classification')

xrf_param <-
  xrf_spec |>
  extract_parameter_set_dials() |>
  update(mtry = mtry(c(1, 16)))

xrf_bst_grid <-
  xrf_param |>
  filter(id != "penalty") |>
  grid_space_filling(size = 25)

penalties <- 10^seq(-6, -1, length.out = 10)
xrf_grid <- crossing(xrf_bst_grid, penalty = penalties)

xrf_stats <- function(x) {
  require(tidymodels)
  require(lorax)
  if (inherits(x, c("model_fit", "workflow"))) {
    x <- extract_fit_engine(x)
  }
  penalties <- 10^seq(-6, -1, length.out = 15)
  xrf_rules <-
    purrr::map_dfr(
      penalties,
      ~ tidy(x, penalty = .x) |> dplyr::mutate(penalty = .x)
    ) |>
    dplyr::filter(rule != "( TRUE )") |>
    dplyr::mutate(
      num_rule_terms = purrr::map_int(rule, ~ length(gregexpr("&", .x)[[1]]))
    )

  xrf_rules |>
    summarize(
      num_coef = length(estimate),
      num_rule_terms = mean(num_rule_terms),
      .by = c(penalty)
    )
}

set.seed(458)
forest_xrf_res <-
  xrf_spec |>
  tune_grid(
    class ~ .,
    resamples = forested_rs,
    grid = xrf_grid,
    param_info = xrf_param,
    control = control_grid(
      save_pred = TRUE,
      save_workflow = TRUE,
      extract = xrf_stats
    ),
    metrics = cls_mtr
  )

forest_xrf_best <- select_best(forest_xrf_res, metric = "brier_class")

forest_xrf_pred <-
  forest_xrf_res |>
  collect_predictions(parameters = forest_xrf_best) |>
  mutate(wflow_id = "xrfoost") |>
  relocate(wflow_id)

forest_xrf_mtr_ex <-
  forest_xrf_pred |>
  cls_mtr(class, estimate = .pred_class, .pred_Yes)

forest_xrf_set_res <-
  as_workflow_set(
    xrfoost = forest_xrf_res |> butcher::butcher(),
  )

# ------------------------------------------------------------------------------

save(list = ls(pattern = "forest_xrf_"), file = "RData/forest_xrf.RData")

if (!interactive()) {
  q("no")
}
