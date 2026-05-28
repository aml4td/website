library(tidymodels)
library(tdl)
library(mirai)
library(bestNormalize)
library(spatialsample)
library(finetune)

load("RData/forested_data.RData")

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
daemons(parallel::detectCores())

# ------------------------------------------------------------------------------

cls_mtr <- metric_set(brier_class, roc_auc, pr_auc, mn_log_loss)

# ------------------------------------------------------------------------------

norm_rec <-
  recipe(class ~ ., data = forested_train) |>
  step_orderNorm(all_numeric_predictors())

autoint_spec <-
  tabular_auto_int(
    epochs = 50L,
    num_embedding = tune(),
    # hidden_units = tune(),
    # hidden_activations = "relu",
    num_attn_feat = tune(),
    num_attn_heads = tune(),
    num_attn_blocks = tune(),
    dropout = tune(),
    dropout_attn = tune(),
    dropout_embedding = tune(),
    penalty = 0,
    learn_rate = tune(),
    rate_schedule = tune(),
    momentum = tune(),
    batch_size = tune(),
    stop_iter = 5
  ) |>
  set_engine(
    "brulee",
    optimizer = "SGD",
  ) |>
  set_mode("classification")

autoint_wflow <- workflow(norm_rec, autoint_spec)

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

autoint_param <-
  autoint_wflow |>
  extract_parameter_set_dials() |>
  update(
    num_attn_feat = num_attn_feat(c(2, 25)),
    num_embedding = num_embedding(c(2, 25))
  )


system.time({
  set.seed(12)
  autoint_res <-
    autoint_wflow |>
    tune_grid(
      resamples = forested_rs,
      grid = 50,
      param_info = autoint_param,
      metrics = cls_mtr,
      control = ctrl
    )
})


# ------------------------------------------------------------------------------

save(
  autoint_res,
  file = "RData/forested_autoint.Rdata"
)

# ------------------------------------------------------------------------------

if (!interactive()) {
  q("no")
}
