library(tidymodels)
library(embed)

# ------------------------------------------------------------------------------

load("../RData/weight_lifting.RData")

# ------------------------------------------------------------------------------

set.seed(822)
weight_split <- initial_split(
  weight_lifting,
  strata = bench_weight,
  breaks = 10
)
weight_train <- training(weight_split)
weight_test <- testing(weight_split)
weight_rs <- vfold_cv(weight_train, strata = bench_weight, breaks = 10)

# ------------------------------------------------------------------------------

dummy_rec <-
  recipe(bench_weight ~ ., data = weight_train) |>
  step_dummy(all_factor_predictors()) |>
  step_zv(all_predictors())

norm_rec <-
  dummy_rec |>
  step_normalize(all_predictors())

nzv_rec <-
  norm_rec |>
  step_nzv(all_predictors())

encoded_rec <-
  recipe(bench_weight ~ ., data = weight_train) |>
  step_lencode_mixed(
    country,
    federation,
    meet_country,
    division,
    outcome = vars(bench_weight)
  ) |>
  step_dummy(all_factor_predictors()) |>
  step_zv(all_predictors()) |>
  step_normalize(all_predictors())
