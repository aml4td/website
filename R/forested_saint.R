# pak::pak(c("tidymodels/tabular@saint"), ask = FALSE)
library(tidymodels)
library(tabular)
library(bestNormalize)
library(spatialsample)
library(finetune)

load("~/content/website/RData/forested_data.RData")

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

cls_mtr <- metric_set(brier_class, roc_auc, pr_auc, mn_log_loss)

# ------------------------------------------------------------------------------

norm_rec <-
 recipe(class ~ ., data = forested_train) |>
 step_orderNorm(all_numeric_predictors())

saint_spec <-
 tabular_saint(
  epochs = 50L,
  num_embedding = tune(),
  num_attn_heads = tune(),
  num_attn_blocks = tune(),
  dropout_attn = tune(),
  attention_type = tune(),
  penalty = 0,
  learn_rate = tune(),
  rate_schedule = tune(),
  momentum = tune(),
  batch_size = tune(),
  stop_iter = 10L
 ) |>
 set_engine(
  "brulee",
  optimizer = "SGD",
  device = "cuda"
 ) |>
 set_mode("classification")

saint_wflow <- workflow(norm_rec, saint_spec)

# ------------------------------------------------------------------------------

pull_iter <- function(x) {
 require(tidymodels)
 require(brulee)
 fit <- extract_fit_engine(x)
 tibble(epoch_actual = fit$best_epoch, num_param = length(unlist(coef(fit))))
}

ctrl <- control_grid(
 save_pred = TRUE,
 save_workflow = TRUE,
 parallel_over = "everything",
 extract = pull_iter
)

# ------------------------------------------------------------------------------

saint_param <-
 saint_wflow |>
 extract_parameter_set_dials() |>
 update(
  num_embedding = num_embedding(c(2, 50)),
  batch_size = batch_size(c(4, 9))
 )


set.seed(12)
saint_res <-
 saint_wflow |>
 tune_grid(
  resamples = forested_rs,
  grid = 25,
  param_info = saint_param,
  metrics = cls_mtr,
  control = ctrl
 )

# ------------------------------------------------------------------------------

save(
 saint_res,
 file = "RData/forested_saint.RData"
)

# ------------------------------------------------------------------------------

if (!interactive()) {
 q("no")
}
