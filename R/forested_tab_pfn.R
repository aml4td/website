library(tidymodels)
library(spatialsample)
library(tdl)
np <- reticulate::import('numpy')
load("~/content/website/RData/forested_data.RData")

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

tabpfn_wflow <- workflow(class ~ ., tabular_pfn(mode = "classification"))

ctrl <- control_resamples(
  save_pred = TRUE,
  save_workflow = TRUE
)

cls_mtr <- metric_set(brier_class, roc_auc, pr_auc, mn_log_loss)

tabpfn_res <-
  tabpfn_wflow |>
  fit_resamples(
    resamples = forested_rs,
    control = ctrl,
    metrics = cls_mtr
  )

pfn_spec <- tabular_pfn(
  mode = "classification",
  num_estimators = tune(),
  softmax_temperature = tune(),
  average_before_softmax = tune()
)
tabpfn_tune_wflow <- workflow(class ~ ., pfn_spec)

tabpfn_tune_param <-
  tabpfn_tune_wflow |>
  extract_parameter_set_dials() |>
  update(
    softmax_temperature = softmax_temperature(c(c(0.5, 1.5))),
    num_estimators = num_estimators(c(1, 20))
  )

tabpfn_tune_res <-
  tabpfn_tune_wflow |>
  tune_grid(
    resamples = forested_rs,
    control = ctrl,
    param_info = tabpfn_tune_param,
    grid = 25,
    metrics = cls_mtr
  )

# ------------------------------------------------------------------------------

save(
  tabpfn_res,
  tabpfn_tune_res,
  file = "RData/forested_tabpfn.Rdata"
)

# ------------------------------------------------------------------------------

if (!interactive()) {
  q("no")
}
