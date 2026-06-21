library(tidymodels)
library(spatialsample)
library(tabular)

# ------------------------------------------------------------------------------

load("~/content/website/RData/forested_data.RData")

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
mirai::daemons(2) # without a gpu, running in parallel requires significant amounts
                  # of memory. These two processes will each peak at around 10GB

# ------------------------------------------------------------------------------

tabicl_wflow <- workflow(class ~ .,
                         tabular_icl(mode = "classification") |> set_engine("brulee", device = "cuda"))

ctrl <- control_resamples(
  save_pred = TRUE,
  save_workflow = TRUE
)

cls_mtr <- metric_set(brier_class, roc_auc, pr_auc, mn_log_loss)

tabicl_res <-
  tabicl_wflow |>
  fit_resamples(
    resamples = forested_rs,
    control = ctrl,
    metrics = cls_mtr
  )

icl_spec <- tabular_icl(
  mode = "classification",
  # TODO add normalization options
  num_estimators = tune(),
  softmax_temperature = tune(),
) |>
 set_engine("brulee", device = "cuda")

tabicl_tune_wflow <- workflow(class ~ ., icl_spec)

tabicl_tune_param <-
  tabicl_tune_wflow |>
  extract_parameter_set_dials() |>
  update(
   num_estimators = num_estimators(c(1, 20)),
   softmax_temperature = softmax_temperature(c(0.5, 1.5)))

tabicl_tune_res <-
  tabicl_tune_wflow |>
  tune_grid(
    resamples = forested_rs,
    control = ctrl,
    param_info = tabicl_tune_param,
    grid = 25,
    metrics = cls_mtr
  )

# ------------------------------------------------------------------------------

save(
  tabicl_res,
  tabicl_tune_res,
  file = "RData/forested_tabicl.Rdata"
)

# ------------------------------------------------------------------------------

if (!interactive()) {
  q("no")
}
