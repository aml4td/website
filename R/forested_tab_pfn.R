library(tidymodels)
library(spatialsample)
library(tabby)
np <- reticulate::import('numpy') # Trigger torch to use OpenMP to avoid conflicts
load("~/content/website/RData/forested_data.RData")

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

ctrl <- control_resamples(
  save_pred = TRUE,
  save_workflow = TRUE
)

cls_mtr <- metric_set(brier_class, roc_auc, pr_auc, mn_log_loss)

pfn_spec <- tabular_pfn(
  mode = "classification",
  num_estimators = tune()
)
tabpfn_tune_wflow <- workflow(class ~ ., pfn_spec)

tabpfn_tune_res <-
  tabpfn_tune_wflow |>
  tune_grid(
    resamples = forested_rs,
    control = ctrl,
    grid = tibble(num_estimators = 1:25),
    metrics = cls_mtr
  )

# ------------------------------------------------------------------------------

save(
  tabpfn_tune_res,
  file = "RData/forested_tabpfn.Rdata"
)

# ------------------------------------------------------------------------------

if (!interactive()) {
  q("no")
}
