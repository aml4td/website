library(tidymodels)
library(tabular)
library(mirai)
library(bestNormalize)
library(spatialsample)

load("~/content/website/RData/forested_data.RData")

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
mirai::daemons(2)

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
    num_attn_feat = tune(),
    num_attn_heads = tune(),
    num_attn_blocks = tune(),
    dropout_attn = tune(),
    dropout_embedding = tune(),
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
    device = "mps"
  ) |>
  set_mode("classification")

autoint_wflow <- workflow(norm_rec, autoint_spec)

# ------------------------------------------------------------------------------

pull_iter <- function(x) {
  require(tidymodels)
  require(brulee)
  fit <- extract_fit_engine(x)
  revived <- brulee:::revive_model(fit$model)
  num_param <- 
    lapply(revived$parameters, function(x) prod(dim(x))) |> 
    as.integer() |> 
    sum()
  
  tibble(
    epoch_best = length(fit$loss),
    epoch_actual = fit$best_epoch,
    num_param = num_param
  )
}

ctrl <- control_grid(
  save_pred = TRUE,
  save_workflow = TRUE,
  parallel_over = "everything",
  extract = pull_iter,
  verbose = TRUE
)

# ------------------------------------------------------------------------------

autoint_param <-
  autoint_wflow |>
  extract_parameter_set_dials() |>
  update(
    num_attn_feat = num_attn_feat(c(2, 50)),
    num_embedding = num_embedding(c(2, 50)),
    batch_size = batch_size(c(4, 9))
  )

set.seed(12)
torch::torch_manual_seed(12)
autoint_res <-
  autoint_wflow |>
  tune_grid(
    resamples = forested_rs,
    grid = 25,
    param_info = autoint_param,
    metrics = cls_mtr,
    control = ctrl
  )

# ------------------------------------------------------------------------------

save(
  autoint_res,
  file = "~/content/website/RData/forested_autoint.RData"
)

# ------------------------------------------------------------------------------

if (!interactive()) {
  q("no")
}