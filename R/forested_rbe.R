library(tidymodels)
library(rbe)
library(spatialsample)
library(mirai)

# ------------------------------------------------------------------------------

daemons(10)
load("RData/forested_data.RData")
cls_mtr <- metric_set(brier_class, roc_auc, pr_auc, mn_log_loss)

# ------------------------------------------------------------------------------

rbe_stats <- function(x) {
  require(tidymodels)
  require(lorax)
  if (inherits(x, c("model_fit", "workflow"))) {
    x <- extract_fit_engine(x)
  }
  # default penalty parameter candidates
  penalties <- dials::penalty(c(-5, -1)) |> dials::value_seq(10)
  rule_length <- function(x) {
    ifelse(x == "NULL", 1, length(gregexpr("&", x)[[1]]) + 1)
  }
  
  purrr::map_dfr(penalties, ~ tidy(x, penalty = .x) |> dplyr::mutate(penalty = .x)) |>
    dplyr::filter(estimate != 0) |>
    dplyr::left_join(x$rules |> dplyr::select(term = label, rules), by = join_by(term)) |>
    dplyr::mutate(rules = map_chr(rules, ~ rlang::expr_deparse(.x, width = 1000))) |>
    dplyr::mutate(num_rule_terms = map_int(rules, rule_length)) |>
    summarize(
      `# Coefficients` = length(estimate),
      `Mean Rule Size` = mean(num_rule_terms),
      .by = c(penalty)
    )
}

# ------------------------------------------------------------------------------

# default penalty parameter candidates
penalties <- penalty(c(-5, -1)) |> value_seq(10)

rbe_spec <-
  rule_fit(
    mtry = tune(),
    trees = 50,
    min_n = 5,
    tree_depth = tune(),
    learn_rate = tune(),
    penalty = tune()
  ) |>
  set_mode('classification') |>
  set_engine("rule_ensemble",
             method = tune(),
             path_values = !!penalties)

rbe_param <-
  rbe_spec |>
  extract_parameter_set_dials() 

rbe_grid <-
  rbe_param |>
  filter(id != "method") |> 
  grid_hybrid(
    reg_parameters = c(penalty),
    reg_levels = 10,
    sfd_size = 20
  ) |> 
  crossing(method = values_boosting_method)

penalties <- sort(unique(rbe_grid$penalty))

set.seed(458)
forest_rbe_res <-
  rbe_spec |>
  tune_grid(
    class ~ .,
    resamples = forested_rs,
    grid = rbe_grid,
    param_info = rbe_param,
    control = control_grid(
      save_pred = TRUE,
      save_workflow = TRUE,
      parallel_over = "everything",
      extract = rbe_stats
    ),
    metrics = cls_mtr
  )

forest_rbe_best <- select_best(forest_rbe_res, metric = "brier_class")

forest_rbe_pred <-
  forest_rbe_res |>
  collect_predictions(parameters = forest_rbe_best) |>
  mutate(wflow_id = "RuleFit") |>
  relocate(wflow_id)

forest_rbe_mtr_ex <-
  forest_rbe_pred |>
  cls_mtr(class, estimate = .pred_class, .pred_Yes)

forest_rbe_set_res <-
  as_workflow_set(rbeoost = forest_rbe_res |> butcher::butcher(), )

# ------------------------------------------------------------------------------

save(list = ls(pattern = "forest_rbe_"), file = "RData/forest_rbe.RData")

if (!interactive()) {
  q("no")
}
