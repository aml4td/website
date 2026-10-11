library(tidymodels)
library(bonsai)
library(embed)
library(mirai)
library(spatialsample)

# ------------------------------------------------------------------------------

load("RData/forested_data.RData")

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
daemons(parallel::detectCores() - 2)

# ------------------------------------------------------------------------------

cls_mtr <- metric_set(brier_class, roc_auc, pr_auc, mn_log_loss)

# ------------------------------------------------------------------------------

encode_rec <-
  recipe(class ~ ., data = forested_train) |>
  step_lencode_mixed(county, outcome = "class")

# ------------------------------------------------------------------------------

crf_spec <-
  rand_forest(
    mode = "classification",
    mtry = tune(),
    trees = 1000
  ) |>
  set_engine("partykit")

set.seed(526)
forest_crf_res <-
  crf_spec |>
  tune_grid(
    encode_rec,
    resamples = forested_rs,
    grid = tibble(mtry = 1:16),
    control = control_grid(
      save_pred = TRUE,
      save_workflow = TRUE
    ),
    metrics = cls_mtr
  )

forest_crf_res <- forest_crf_res |> butcher::butcher()

forest_crf_set_res <- as_workflow_set("Cond. Inf. Forests" = forest_crf_res)

# ------------------------------------------------------------------------------

save(forest_crf_set_res, file = "RData/forest_crf.RData")

# ------------------------------------------------------------------------------

if (!interactive()) {
  q("no")
}
