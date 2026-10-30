library(tidymodels)
library(bonsai)
library(spatialsample)
library(mirai)

if (!rlang::is_installed("catboost")) {
  # See https://catboost.ai/docs/en/installation/r-installation-binary-installation

  version <- "1.2.10"
  template <- "https://github.com/catboost/catboost/releases/download/v{version}/catboost-R-darwin-universal2-{version}.tgz"

  target_url <- glue::glue(template)
  target_dest <- tempfile()
  download.file(target_url, target_dest)

  inst <- glue::glue("R CMD INSTALL  --no-staged-install {target_dest}")

  # Deep breath
  system(inst)
}

# ------------------------------------------------------------------------------

daemons(7)
load("RData/forested_data.RData")
cls_mtr <- metric_set(brier_class, roc_auc, pr_auc, mn_log_loss)

# ------------------------------------------------------------------------------

# Summarize the rules of a tree ensemble: the mean number of terms and of
# distinct predictors per rule, and the total number of terminal nodes.
#
# Why this is chunked: extract_rules() builds one R expression per terminal
# node (about 5 KB each). catboost grows symmetric trees, so a depth-16 tree
# can have thousands of rules and extracting 500 of them at once needs tens of
# GB per worker. C5.0, lightgbm, and xgboost trees are capped by leaf count so
# they never get that large.
#
# How it works: the three results are all sums over rules (a mean is a sum
# divided by a count), so we do not need every rule at the same time. We
# extract `chunk_size` trees, keep only the three sums, and let the rules go
# out of scope before the next chunk. Peak memory depends on `chunk_size` and
# the rules per tree, not on the number of trees. The result is the same as
# extracting all trees at once.
#
# `data` is only needed by some engines (e.g., catboost and ranger need it to
# decode categorical splits). It is passed on only when supplied.
ensmbl_stats <- function(x, data = NULL, chunk_size = 10L) {
  require(tidymodels)
  require(lorax)
  if (inherits(x, c("model_fit", "workflow"))) {
    x <- extract_fit_engine(x)
  }
  num_members <- num_ensemble_members(x)
  mem_seq <- seq_len(num_members)

  # List of integer vectors, each with up to `chunk_size` tree numbers
  chunks <- split(mem_seq, ceiling(mem_seq / chunk_size))

  # Build the optional arguments separately so `data` is not passed (and does
  # not trigger an error) for engines that do not accept it
  extra_args <- list()
  if (!is.null(data)) {
    extra_args$data <- data
  }

  # One row of sums per chunk. Only these sums are kept; the rule table for the
  # chunk is freed once the function returns
  parts <- lapply(chunks, function(tr) {
    args <- c(list(x, tree = tr, add_statistics = TRUE), extra_args)
    rule_df <- do.call(extract_rules, args)
    tibble::tibble(
      terms = sum(rule_df$num_rule_terms),
      predictors = sum(rule_df$num_rule_predictors),
      nodes = nrow(rule_df)
    )
  })

  # Combine the chunks. Dividing the total by the total node count gives the
  # same means as calling mean() on the full rule table (not a mean of chunk
  # means, which would be wrong when chunks have different numbers of rules)
  totals <- dplyr::bind_rows(parts) |>
    dplyr::summarize(
      terms = sum(terms),
      predictors = sum(predictors),
      nodes = sum(nodes)
    )

  tibble::tibble(
    num_rule_terms = totals$terms / totals$nodes,
    num_rule_predictors = totals$predictors / totals$nodes,
    num_terminal_nodes = totals$nodes,
    num_members = num_members
  )
}

# ------------------------------------------------------------------------------

# The workers do not have our global environment, so a function that refers to
# `forested_train` (or to `ensmbl_stats()`) by name would fail there. This
# builds a closure that carries both objects with it: the environment of a
# function made inside another function is sent to the workers along with the
# function. The data is shared with mori, so the workers map the same memory
# instead of receiving a copy. The shared object must stay referenced in this
# session while the workers use it (the closure does that).
# tune calls the extractor with a single argument, the fitted workflow.
make_extractor <- function(fn, data) {
  force(fn)
  force(data)
  function(x) fn(x, data = data)
}

ensmbl_stats_extractor <- make_extractor(
  ensmbl_stats,
  mori::share(forested_train)
)

# ------------------------------------------------------------------------------

ctb_spec <-
  boost_tree(
    mode = "classification",
    trees = 1000,
    min_n = tune(),
    mtry = tune(),
    tree_depth = tune(),
    learn_rate = tune(),
    stop_iter = 5
  ) |>
  set_engine("catboost", validation = 0.1)

ctb_param <-
  ctb_spec |>
  extract_parameter_set_dials() |>
  update(
    tree_depth = tree_depth(c(2, 16))
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
      extract = ensmbl_stats_extractor,
      save_pred = TRUE,
      save_workflow = TRUE
    ),
    metrics = cls_mtr
  )

forest_ctb_best <- select_best(forest_ctb_res, metric = "brier_class")

forest_ctb_pred <-
  forest_ctb_res |>
  collect_predictions(parameters = forest_ctb_best) |>
  mutate(wflow_id = "CatBoost") |>
  relocate(wflow_id)

forest_ctb_mtr_ex <-
  forest_ctb_pred |>
  cls_mtr(class, estimate = .pred_class, .pred_Yes)

forest_ctb_set_res <-
  as_workflow_set(
    CatBoost = forest_ctb_res |> butcher::butcher(),
  )

# ------------------------------------------------------------------------------

save(list = ls(pattern = "forest_ctb_"), file = "RData/forest_catboost.RData")
