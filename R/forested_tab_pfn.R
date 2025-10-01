library(tidymodels)
library(TabPFN)
library(spatialsample)
library(tidymodels)

reticulate::use_virtualenv("~/.virtualenvs/r-tabpfn")

load("~/content/website/RData/forested_data.RData")

# ------------------------------------------------------------------------------
# Measure effect of different "training set" sizes

preds <- NULL

for (i in seq(500, 4000, by = 500)) {
  fit_time <-
    system.time({
      set.seed(3823)
      mod_1 <- tab_pfn(
        class ~ .,
        data = forested_train |> dplyr::slice_sample(n = i)
      )
    })
  pred_time <- system.time({
    set.seed(27)
    pred_1a <-
      predict(mod_1, forested_test) %>%
      add_rowindex() %>%
      mutate(starting = i)
  })
  pred_1a$pred_time <- pred_time[3]
  pred_1a$model_time <- fit_time[3]
  preds <- bind_rows(preds, pred_1a)
  rm(pred_1a)
}

# errored at i = 4500
# Prediction failed: Error in py_call_impl(callable, call_args$unnamed, call_args$named) : RuntimeError:
# MPS backend out of memory (MPS allocated: 4.74 GiB, other allocations: 32.99 GiB, max allowed: 45.90 GiB). Tried
# to allocate 9.96 GiB on private pool. Use PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0 to disable upper limit for memory


target_rows <- function(x, probs = c(0.1, 0.25, 0.5, 0.75, 0.9)) {
  res <- NULL
  for (i in probs) {
    tmp <-
      x %>%
      summarize(med = median(.pred_Yes), .by = .row) %>%
      arrange(abs(med - i)) |>
      slice(1) |>
      select(.row) |>
      mutate(target = i)
    res <- bind_rows(res, tmp)
  }
  res %>% mutate(target = format(target))
}

tabpfn_example_preds <- 
  preds %>% 
  inner_join(target_rows(preds))
tabpfn_example_times <- 
  preds %>% 
  summarize(fit = mean(model_time), predict = mean(pred_time), .by = starting)

split_data <- function(split) {
  list(
    fit = analysis(split),
    pred = assessment(split)
  )
}

# ------------------------------------------------------------------------------
# Compute results for forested data

data_splits <- map(forested_rs$splits, split_data)

tpn_size <- 4000

cls_mtr <- metric_set(brier_class, roc_auc)

tabpfn_cv_mtr <- tabpfn_cv_pred <- NULL

for (i in seq_along(data_splits)) {
  set.seed(3823)
  fit <- tab_pfn(
    class ~ .,
    data = data_splits[[i]]$fit |> dplyr::slice_sample(n = tpn_size)
  )
  pred <- predict(fit, data_splits[[i]]$pred) |>
    bind_cols(data_splits[[i]]$pred |> select(class)) |>
    mutate(id = forested_rs$id[i])
  mtr <-
    cls_mtr(pred, class, estimate = .pred_class, .pred_Yes) |>
    mutate(id = forested_rs$id[i])

  tabpfn_cv_mtr <- bind_rows(tabpfn_cv_mtr, mtr)
  tabpfn_cv_pred <- bind_rows(tabpfn_cv_pred, pred)
  rm(fit, pred, mtr)
}

# ------------------------------------------------------------------------------

save(list = ls(pattern = "^tabpfn_"), 
     file = "~/content/website/RData/forested_tabpfn.RData")
