library(tidymodels)
library(spatialsample)
library(tabby)

# ------------------------------------------------------------------------------

load("~/content/website/RData/forested_data.RData")

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
mirai::daemons(2) # without a gpu, running in parallel requires significant amounts
# of memory. These two processes will each peak at around 10GB

# ------------------------------------------------------------------------------

ctrl <- control_resamples(
  save_pred = TRUE,
  save_workflow = TRUE
)

cls_mtr <- metric_set(brier_class, roc_auc, pr_auc, mn_log_loss)


icl_spec <- tabular_icl(
  mode = "classification",
  num_estimators = tune()
) |>
  set_engine("brulee", device = "cuda")

tabicl_tune_wflow <- workflow(class ~ ., icl_spec)

tabicl_tune_res <-
  tabicl_tune_wflow |>
  tune_grid(
    resamples = forested_rs,
    control = ctrl,
    grid = tibble(num_estimators = 1:25),
    metrics = cls_mtr
  )

# ------------------------------------------------------------------------------

save(
  tabicl_tune_res,
  file = "RData/forested_tabicl.Rdata"
)

# ------------------------------------------------------------------------------

if (!interactive()) {
  q("no")
}
