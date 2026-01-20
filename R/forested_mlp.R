library(tidymodels)
library(bestNormalize)
library(embed)
library(mirai)
library(spatialsample)
library(finetune)

load("RData/forested_data.RData")

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
daemons(parallel::detectCores())

# ------------------------------------------------------------------------------

encode_rec <-
  recipe(class ~ ., data = forested_train) |>
  step_lencode_mixed(county, outcome = "class") |>
  step_orderNorm(all_numeric_predictors())

encode_pca_rec <-
  encode_rec |>
  step_pca(all_numeric_predictors(), -county, threshold = 1) |>
  step_orderNorm(starts_with("PC"))

dummy_on_rec <-
  recipe(class ~ ., data = forested_train) |>
  step_dummy(county) |>
  step_zv(all_predictors()) |>
  step_orderNorm(all_numeric_predictors())

dummy_on_pca_rec <-
  dummy_on_rec |>
  step_pca(all_numeric_predictors(), -starts_with("county"), threshold = 1) |>
  step_orderNorm(starts_with("PC"))

dummy_cs_rec <-
  recipe(class ~ ., data = forested_train) |>
  step_dummy(county) |>
  step_zv(all_predictors()) |>
  step_normalize(all_numeric_predictors())

dummy_cs_pca_rec <-
  dummy_cs_rec |>
  step_pca(all_numeric_predictors(), -starts_with("county"), threshold = 1) |>
  step_normalize(starts_with("PC"))

# ------------------------------------------------------------------------------

mlp_adam_spec <-
  mlp(
    hidden_units = tune(),
    penalty = tune(),
    learn_rate = tune(),
    epochs = 25,
    activation = tune()
  ) |>
  set_engine(
    "brulee",
    stop_iter = 5,
    optimizer = "ADAMw",
    verbose = FALSE,
    rate_schedule = tune(),
    batch_size = tune(),
    momentum = tune()
  ) |>
  set_mode("classification")

mlp_adam_2layer_spec <-
  mlp(
    hidden_units = tune(),
    penalty = tune(),
    learn_rate = tune(),
    epochs = 25,
    activation = tune()
  ) |>
  set_engine(
    "brulee_two_layer",
    hidden_units_2 = tune(),
    activation_2 = tune(),
    stop_iter = 5,
    optimizer = "ADAMw",
    verbose = FALSE,
    rate_schedule = tune(),
    batch_size = tune(),
    momentum = tune()
  ) |>
  set_mode("classification")

mlp_wflow_set <-
  workflow_set(
    preproc = list(
      encoded_none = encode_rec,
      orderNorm_none = dummy_on_rec,
      plain_none = dummy_cs_rec,
      encoded_pca = encode_pca_rec,
      orderNorm_pca = dummy_on_pca_rec,
      plain_pca = dummy_cs_pca_rec
    ),
    models = list(
      `1L_AdamW` = mlp_adam_spec,
      `2L_AdamW` = mlp_adam_2layer_spec
    )
  ) |>
  option_add_parameters()

# ------------------------------------------------------------------------------

pull_iter <- function(x) {
  require(tidymodels)
  fit <- extract_fit_engine(x)
  tibble(epoch_actual = fit$best_epoch, num_param = length(unlist(coef(fit))))
}

ctrl <- control_race(
  save_pred = TRUE,
  parallel_over = "everything",
  extract = pull_iter
)

mlp_wflow_set <-
  mlp_wflow_set |>
  option_add(control = ctrl)

for (i in 1:nrow(mlp_wflow_set)) {
  wflow_id <- mlp_wflow_set$wflow_id[[i]]

  prm <- mlp_wflow_set$option[[i]]$param_info
  prm <- prm |>
    update(
      momentum = momentum(c(0.8, 0.99)),
      penalty = penalty(c(-10, -1)),
      learn_rate = learn_rate(c(-4, -1)),
      activation = activation(c("elu", "relu", "tanh", "tanhshrink")),
      rate_schedule = rate_schedule(c("cyclic", "decay_time", "none"))
    )
  mlp_wflow_set$option[[i]]$param_info <- prm
}

# ------------------------------------------------------------------------------

set.seed(12)
mlp_grid_res <-
  mlp_wflow_set |>
  workflow_map(
    resamples = forested_rs,
    grid = 25,
    verbose = TRUE
  )

# ------------------------------------------------------------------------------

mlp_ranks <-
  mlp_grid_res |>
  rank_results(rank_metric = "brier_class")

# ------------------------------------------------------------------------------

mlp_best_mtr <-
  mlp_grid_res |>
  mutate(.metrics = map(result, ~ collect_metrics(.x))) |>
  select(wflow_id, .metrics) |>
  unnest(.metrics)

mlp_collect <-
  mlp_grid_res |>
  mutate(
    epochs = map(
      result,
      ~ collect_extracts(.x)
    )
  ) |>
  select(wflow_id, epochs) |>
  unnest(epochs) |>
  filter(map_lgl(.extracts, ~ inherits(.x, "data.frame"))) |>
  unnest(.extracts)

epoch_actual <- mlp_collect

mlp_collect <-
  mlp_collect |>
  summarize(
    epoch_min = min(epoch_actual),
    epoch_max = max(epoch_actual),
    epoch_mean = mean(epoch_actual),
    epoch_sd = sd(epoch_actual),
    num_param = mean(num_param),
    .by = c(.config, wflow_id)
  )

brier_and_params <-
  full_join(mlp_ranks, mlp_collect, by = join_by(wflow_id, .config)) |>
  filter(.metric == "brier_class") |>
  # some models failed
  filter(!is.na(num_param))

# ------------------------------------------------------------------------------

best_id <-
  mlp_ranks |>
  filter(.metric == "brier_class") |>
  slice_min(mean, n = 5) |>
  inner_join(
    brier_and_params |> select(wflow_id, .config, num_param),
    by = join_by(wflow_id, .config)
  ) |>
  slice_min(num_param, n = 1) |>
  pluck("wflow_id")

print(best_id)

# ------------------------------------------------------------------------------

mlp_best_res <-
  mlp_grid_res |>
  extract_workflow_set_result(id = best_id)

mlp_best_config <- select_best(mlp_best_res, metric = "brier_class")

# ------------------------------------------------------------------------------

save(
  mlp_ranks,
  best_id,
  mlp_best_res,
  mlp_best_config,
  brier_and_params,
  mlp_best_mtr,
  epoch_actual,
  file = "RData/forested_mlp.Rdata"
)

# ------------------------------------------------------------------------------

if (!interactive()) {
  q("no")
}
