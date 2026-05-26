library(tidymodels)
library(brulee)
library(bestNormalize)
library(tdl)
library(embed)
library(butcher)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
mirai::daemons(10)

# ------------------------------------------------------------------------------

load("~/content/website/RData/forested_data.RData")

# ------------------------------------------------------------------------------

pull_iter <- function(x) {
  require(tidymodels)
  require(brulee)
  fit <- extract_fit_engine(x)
  tibble(epoch_actual = fit$best_epoch,
         num_param = length(unlist(coef(fit))))
}

# fmt: skip
extract_wflow <- function(x) x

ctrl <- control_grid(parallel_over = "everything",
                     save_pred = TRUE,
                     save_workflow = TRUE,
                     extract = pull_iter)
cls_mtr <- metric_set(brier_class, roc_auc, pr_auc, mn_log_loss)

encode_rec <-
  recipe(class ~ ., data = forested_train) |>
  step_lencode_mixed(county, outcome = "class") |>
  step_orderNorm(all_numeric_predictors())

# ------------------------------------------------------------------------------

resnet_list <- vector(mode = "list", length = 6)
names(resnet_list) <- map_chr(1:6, ~ cli::format_inline("{.x} layer{?s}"))

for (lyr in seq_along(resnet_list)) {
  cli::cli_inform(format(Sys.time()))
  
  lyrs <- 1:lyr
  rn_spec <-
    tabular_resnet(
      hidden_units = tune(),
      batch_norm_units = tune(),
      penalty = tune(),
      learn_rate = tune(),
      epochs = 50L,
      activation = tune()
    ) |>
    set_mode("classification") |>
    set_engine(
      "brulee",
      stop_iter = 5,
      residual_at = !!lyrs,
      optimizer = "ADAMw",
      verbose = FALSE,
      rate_schedule = tune(),
      batch_size = tune(),
      momentum = tune()
    )
  
  rn_wflow <- workflow(encode_rec, rn_spec)
  
  grd <- neural_net_grid_space_filling(rn_wflow, num_layers = lyr, size = 25)
  
  set.seed(2937)
  rn_res <-
    rn_wflow |>
    tune_grid(
      resamples = forested_rs,
      grid = grd,
      control = ctrl,
      metrics = cls_mtr
    )
  
  resnet_list[[lyr]] <- rn_res
}

forest_resnet_set_res <- as_workflow_set(!!!resnet_list)

# ------------------------------------------------------------------------------

resnet_ranks <-
  forest_resnet_set_res |>
  rank_results(rank_metric = "brier_class")

# ------------------------------------------------------------------------------

resnet_best_mtr <-
  forest_resnet_set_res |>
  mutate(.metrics = map(result, ~ collect_metrics(.x))) |>
  select(wflow_id, .metrics) |>
  unnest(.metrics)

resnet_collect <-
  forest_resnet_set_res |>
  mutate(epochs = map(result, ~ collect_extracts(.x))) |>
  select(wflow_id, epochs) |>
  unnest(epochs) |>
  filter(map_lgl(.extracts, ~ inherits(.x, "data.frame"))) |>
  unnest(.extracts)

epoch_actual <- resnet_collect

resnet_collect <-
  resnet_collect |>
  summarize(
    epoch_min = min(epoch_actual),
    epoch_max = max(epoch_actual),
    epoch_mean = mean(epoch_actual),
    epoch_sd = sd(epoch_actual),
    num_param = mean(num_param),
    .by = c(.config, wflow_id)
  )

brier_and_params <-
  full_join(resnet_ranks, resnet_collect, by = join_by(wflow_id, .config)) |>
  filter(.metric == "brier_class") |>
  # some models failed
  filter(!is.na(num_param))

# ------------------------------------------------------------------------------

best_id <-
  resnet_ranks |>
  filter(.metric == "brier_class") |>
  slice_min(mean, n = 5) |>
  inner_join(brier_and_params |> select(wflow_id, .config, num_param),
             by = join_by(wflow_id, .config)) |>
  slice_min(num_param, n = 1) |>
  pluck("wflow_id")

print(best_id)

# ------------------------------------------------------------------------------

resnet_best_res <-
  forest_resnet_set_res |>
  extract_workflow_set_result(id = best_id)

resnet_best_config <- select_best(resnet_best_res, metric = "brier_class")

# ------------------------------------------------------------------------------

save(
  resnet_ranks,
  best_id,
  resnet_best_res,
  resnet_best_config,
  brier_and_params,
  resnet_best_mtr,
  epoch_actual,
  file = "RData/forested_resnet.Rdata"
)

forest_resnet_set_res <-
  forest_resnet_set_res |>
  butcher::butcher()

save(forest_resnet_set_res, file = "RData/forest_resnet_set_res.Rdata")

# ------------------------------------------------------------------------------

if (!interactive()) {
  q("no")
}
