library(tidymodels)
library(bestNormalize)
library(embed)

load("RData/forested_data.RData")

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

forest_rec <-
  recipe(class ~ ., data = forested_train) |>
  step_lencode_mixed(county, outcome = "class") |>
  step_orderNorm(all_numeric_predictors())

nnet_gd_spec <-
  mlp(
    hidden_units = c(30, 5),
    penalty = 0.15,
    learn_rate = 0.1,
    epochs = 100,
    activation = c("relu", "relu")
  ) |>
  set_engine(
    "brulee",
    stop_iter = 5,
    optimizer = "SGD",
    verbose = FALSE,
    rate_schedule = "step",
    batch_size = ceiling(nrow(forested_train))
  ) |>
  set_mode("classification")


nnet_sgd_nomo_spec <-
  mlp(
    hidden_units = c(30, 5),
    penalty = 0.15,
    learn_rate = 0.1,
    epochs = 100,
    activation = c("relu", "relu")
  ) |>
  set_engine(
    "brulee",
    stop_iter = 5,
    optimizer = "SGD",
    verbose = FALSE,
    rate_schedule = "step",
    batch_size = 2^6
  ) |>
  set_mode("classification")

nnet_sgd_spec <-
  mlp(
    hidden_units = c(30, 5),
    penalty = 0.15,
    learn_rate = 0.1,
    epochs = 100,
    activation = c("relu", "relu")
  ) |>
  set_engine(
    "brulee",
    stop_iter = 5,
    optimizer = "SGD",
    verbose = FALSE,
    rate_schedule = "step",
    batch_size = 2^6,
    momentum = 0.8
  ) |>
  set_mode("classification")

nnet_lbfgs_spec <-
  mlp(
    hidden_units = c(30, 5),
    penalty = 0.15,
    learn_rate = 0.1,
    epochs = 100,
    activation = c("relu", "relu")
  ) |>
  set_engine(
    "brulee",
    stop_iter = 5,
    optimizer = "LBFGS",
    verbose = FALSE,
    rate_schedule = "step",
    batch_size = ceiling(nrow(forested_train))
  ) |>
  set_mode("classification")


nnet_gd_wflow <- workflow(forest_rec, nnet_gd_spec)
nnet_sgd_wflow <- workflow(forest_rec, nnet_sgd_spec)
nnet_sgd_nomo_wflow <- workflow(forest_rec, nnet_sgd_nomo_spec)
nnet_lbfgs_wflow <- workflow(forest_rec, nnet_lbfgs_spec)

# ------------------------------------------------------------------------------

# set.seed(548)
set.seed(12)
seeds <- sample.int(1000, 5)

res_gd <- res_sgd <- res_lbfgs <- res_sgd_nomo <- NULL

for (i in seq_along(seeds)) {
  set.seed(seeds[i])
  nnet_gd_time <- 
    system.time(
      nnet_gd_fit <- fit(nnet_gd_wflow, forested_train)
    )
  tmp_gd <- 
    tibble(
      loss = nnet_gd_fit$fit$fit$fit$loss, 
      seed = i,
      stop_epoch = nnet_gd_fit$fit$fit$fit$best_epoch,
      time = nnet_gd_time[3]
    ) |> 
    mutate(epoch = row_number() - 1, method = "GD")
  res_gd <- bind_rows(res_gd, tmp_gd)
  
  ### 
  
  set.seed(seeds[i])
  nnet_sgd_time <- 
    system.time(
      nnet_sgd_fit <- fit(nnet_sgd_wflow, forested_train)
    )
  tmp_sgd <- 
    tibble(
      loss = nnet_sgd_fit$fit$fit$fit$loss, 
      seed = i,
      stop_epoch = nnet_sgd_fit$fit$fit$fit$best_epoch,
      time = nnet_sgd_time[3]
    ) |> 
    mutate(epoch = row_number() - 1, method = "SGD with momentum")
  res_sgd <- bind_rows(res_sgd, tmp_sgd)
  
  ### 
  
  set.seed(seeds[i])
  nnet_sgd_nomo_time <- 
    system.time(
      nnet_sgd_nomo_fit <- fit(nnet_sgd_nomo_wflow, forested_train)
    )
  tmp_sgd_nomo <- 
    tibble(
      loss = nnet_sgd_nomo_fit$fit$fit$fit$loss, 
      seed = i,
      stop_epoch = nnet_sgd_nomo_fit$fit$fit$fit$best_epoch,
      time = nnet_sgd_nomo_time[3]
    ) |> 
    mutate(epoch = row_number() - 1, method = "SGD")
  res_sgd_nomo <- bind_rows(res_sgd_nomo, tmp_sgd_nomo)
  
  ### 
  
  set.seed(seeds[i])
  nnet_lbfgs_time <- 
    system.time(
      nnet_lbfgs_fit <- fit(nnet_lbfgs_wflow, forested_train)
    )
  tmp_lbfgs <- 
    tibble(
      loss = nnet_lbfgs_fit$fit$fit$fit$loss, 
      seed = i,
      stop_epoch = nnet_lbfgs_fit$fit$fit$fit$best_epoch,
      time = nnet_lbfgs_time[3]
    ) |> 
    mutate(epoch = row_number() - 1, method = "L-BFGS")
  res_lbfgs <- bind_rows(res_lbfgs, tmp_lbfgs)
}

# ------------------------------------------------------------------------------

all_raw_res <- bind_rows(res_gd, res_sgd, res_lbfgs, res_sgd_nomo)

optimizers <- 
  all_raw_res |>  
  filter(epoch == 0) |>
  select(seed, srt = loss, method) |>
  full_join(all_raw_res, by = c("method", "seed")) |>
  mutate(
    max_loss = max(loss),
    loss_norm = loss + max_loss - srt,
    seed = factor(seed),
    method = factor(method, levels = c("GD", "L-BFGS", "SGD", "SGD with momentum"))
  ) |>
  filter(epoch <= stop_epoch)

# optimizers |> 
#   ggplot(aes(epoch, loss_norm, col = seed, group = seed)) +
#   geom_line(show.legend = FALSE,
#             linewidth = 1,
#             alpha = 1 / 2) +
#   facet_wrap(~ method, scale = "free_x", nrow = 1) +
#   scale_x_continuous(breaks = pretty_breaks()) + 
#   labs(x = "Epochs", y = "Cross-Entropy (Validation)")

optimizer_times <-
  all_raw_res |> 
  filter(epoch == 0) |> 
  summarize(
    per_epoch = median(time / stop_epoch),
    .by = c(seed, method)
  ) |> 
  summarize(
    per_epoch = median(per_epoch),
    .by = c(method)
  )

num_optimizer_param <- length(unlist(coef(nnet_lbfgs_fit$fit$fit$fit)))

save(optimizers, optimizer_times, num_optimizer_param, file = "RData/optimizers.RData")
