library(tidymodels)
library(caret)
library(doParallel)

# ------------------------------------------------------------------------------

tidymodels_prefer()
cl <- makePSOCKcluster(parallel::detectCores(logical = FALSE))
registerDoParallel(cl)

# ------------------------------------------------------------------------------

n_train <- 10^3
n_test <- 10^5
num_extra <- 20

# ------------------------------------------------------------------------------

set.seed(212)
sim_tr <- sim_regression(n_train, method = "hooker_2004")
sim_te <- sim_regression(n_test,  method = "hooker_2004")

set.seed(348)
sim_tr <- sim_tr %>% bind_cols(sim_noise(n_train, num_extra))
sim_te <- sim_te %>% bind_cols(sim_noise(n_test,  num_extra))

# warning: Setting row names on a tibble is deprecated.
sim_tr <- as.data.frame(sim_tr)

num_pred <- ncol(sim_tr) - 1

# ------------------------------------------------------------------------------

brulee_sa <- caretSA
brulee_sa$fit <- function (x, y, lev = NULL, last = FALSE, ...)  {
  require(tidymodels)

  if (is.vector(x)) {
    x <- data.frame(x = x)
  }

  dat <- x
  dat$outcome <- y

  sim_rec <-
    recipe(outcome ~ ., data = dat) %>%
    step_normalize(all_predictors())

  mlp_spec <-
    mlp(hidden_units = 20, penalty = 0.05, epochs = 250,
        activation = "relu", learn_rate = 0.05) %>%
    set_engine("brulee", stop_iter = 3) %>%
    set_mode("regression")

  mlp_wflow <- workflow(sim_rec, mlp_spec)
  # res <- fit_resamples(mlp_wflow, resamples = vfold_cv(dat))

  mod <- fit(mlp_wflow, dat)
  # list(resamples = res, fit = mod)
  mod
}

brulee_sa$pred <- function (object, x)  {
  predict(object, x)$.pred
}

brulee_sa$fitness_intern <- function (object, x, y, maximize, p) {
  res <- yardstick:::rmse_vec(y, predict(object, x)$.pred)
  c(RMSE = res)
}

# ------------------------------------------------------------------------------


ctrl <-
  safsControl(
    functions = brulee_sa,
    method = "cv",
    verbose = TRUE,
    allowParallel = TRUE,
    returnResamp = "all"

  )

nnet_sa_time <-
  system.time({
    set.seed(486)
    nnet_sa <-
      safs(x = sim_tr %>% select(-outcome),
           y = sim_tr$outcome,
           iters = 150,
           safsControl = ctrl)
  })[3]


nnet_sa_res <- nnet_sa
nnet_sa_res$fit <- NULL
nnet_sa_res$control <- NULL
nnet_sa_res$sa$fit <- NULL
nnet_sa_res$sa$final

na_sa_plot_data <- plot(nnet_sa)$dataw

sim_te$.pred <- predict(nnet_sa, sim_te)

save(nnet_sa_res, na_sa_plot_data, sim_te, file = "RData/nnet_sa_res.RData")
