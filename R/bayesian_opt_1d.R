library(tidymodels)
library(GPfit)


fn <- function(x) x * cos(.5 * x)

# ------------------------------------------------------------------------------

x_seq <- seq(-10, 10, length.out = 1000)
x_seq_mat <- matrix(x_seq, ncol = 1)
y_seq <- fn(x_seq)

true_curve <- dplyr::tibble(x = x_seq, y = y_seq)

# ------------------------------------------------------------------------------

iter <- 15

set.seed(1)
x_vals <- c(-8,  3)
n_0 <- length(x_vals)
y_vals <- fn(x_vals) + rnorm(1, sd = 1 / 4)
obs_dat <- dplyr::tibble(x = rep(NA, iter + n_0), y = rep(NA, iter + n_0))
obs_dat$x[seq_along(x_vals)] <- x_vals
obs_dat$y[seq_along(x_vals)] <- y_vals
obs_dat$iteration <- c(rep(0, n_0), 1:iter)

gp_pred <- vector(mode = "list", length = iter + 1)

rng <- function(x) (x - (-10)) / 20

rng_obs <- function(x) (x - min(x)) / (max(x) - min(x))



for (i in 1:iter) {
  y_best <- min(obs_dat$y, na.rm = TRUE)
  x_scaled <- rng(x_vals)
  x_mat <- matrix(x_scaled, ncol = 1)
  mod_fit <- GP_fit(x_mat, y_vals)
  pred_lst <- predict(mod_fit, rng(x_seq_mat))
  pred_df <- dplyr::tibble(x = x_seq_mat[,1], .mean = pred_lst$Y_hat,
                           .sd = sqrt(pred_lst$MSE))
  exp_imp <- predict(exp_improve(eps = 0.1), pred_df, maximize = FALSE, iter = 1, best = y_best)
  gp_pred[[i]] <-
    bind_cols(pred_df, exp_imp) %>%
    mutate(
      objective = if_else(objective < 0, 0, objective),
      objective = rng_obs(objective))

  new_best <- x_seq_mat[which.max(exp_imp$objective)]
  cli::cli_inform("new best at {new_best}")
  new_y <- fn(new_best) + rnorm(1, sd = 1 / 4)
  x_vals <- c(x_vals, new_best)
  y_vals <- c(y_vals, new_y)

  obs_dat$x[seq_along(x_vals)] <- x_vals
  obs_dat$y[seq_along(x_vals)] <- y_vals

}

ggplot(pred_df, aes(x)) +
  geom_line(data = true_curve, aes(y = y), alpha = 1 / 5, linewidth = 1) +
  geom_line(aes(y = .mean)) +
  geom_point(data = obs_dat, aes(y = y)) +
  theme_bw()
ggplot(gp_pred[[i]], aes(x, objective)) + geom_line()

save(obs_dat, true_curve, gp_pred, file = "RData/bayesian_opt_1d.RData")
