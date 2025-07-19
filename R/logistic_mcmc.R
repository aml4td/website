library(dplyr)
library(ggplot2)
library(tidyr)
library(cli)
library(broom)

# ------------------------------------------------------------------------------
# Settings

true_means <- c(1.0, -1.5)
post_std_dev <- c(10.0, 10.0)
num_samples <- 100
num_iter <- 20000
width <- 2.0
verbose <- FALSE

# ------------------------------------------------------------------------------
# Generate data

set.seed(1)
x <- runif(num_samples, min = -1)

set.seed(2)
tr_data <- tibble::tibble(
  x = x,
  lp = true_means[1] + true_means[2] * x,
  truth = plogis(lp),
  random = runif(num_samples),
  class = factor(ifelse(random <= truth, "A", "B"))
)

y_bin <- ifelse(tr_data$class == "A", 1, 0)

mle_res <- glm(class ~ x, data = tr_data, family = binomial)
tidy(mle_res)

# ------------------------------------------------------------------------------
# Code to get log-posterior from data and parameters

get_log_post <- function(beta_0, beta_1) {
  pred_probs <- plogis(beta_0 + beta_1 * x)
  log_lik <- dbinom(y_bin, 1, pred_probs, log = TRUE)
  log_prior <-
    dnorm(beta_0, 0, post_std_dev[1], log = TRUE) +
    dnorm(beta_1, 0, post_std_dev[2], log = TRUE)
  sum(log_lik + log_prior)
}

# ------------------------------------------------------------------------------
# MCMC iterations

set.seed(189)
param <- tibble(
  iteration = 0:num_iter,
  beta_0 = NA_real_,
  beta_1 = NA_real_,
  distance = NA_real_,
  log_post = NA_real_,
  current_row = NA_integer_,
  better = NA,
  accept_prob = NA_real_,
  random = runif(num_iter + 1),
  accept = NA
)

# ------------------------------------------------------------------------------
# Initial proposal results

param$current_row[1] <- 1
param$better[1] <- param$accept[1] <- TRUE
param$beta_0[1] <- rnorm(1, 0, post_std_dev[1])
param$beta_1[1] <- rnorm(1, 0, post_std_dev[2])
param$distance[1] <-
  (param$beta_0[1] - true_means[1])^2 +
  (param$beta_1[1] - true_means[2])^2
param$log_post[1] <- get_log_post(param$beta_0[1], param$beta_1[1])

# ------------------------------------------------------------------------------
# Optimization

for (i in 2:(num_iter + 1)) {
  curr <- param$current_row[i - 1]

  param$beta_0[i] <-
    runif(1, min = param$beta_0[curr] - width, max = param$beta_0[curr] + width)
  param$beta_1[i] <-
    runif(1, min = param$beta_1[curr] - width, max = param$beta_1[curr] + width)

  param$distance[i] <-
    (param$beta_0[i] - true_means[1])^2 +
    (param$beta_1[i] - true_means[2])^2

  param$log_post[i] <- get_log_post(param$beta_0[i], param$beta_1[i])

  param$better[i] <- param$log_post[i] > param$log_post[curr]

  if (param$better[i]) {
    if (verbose) {cli_alert_success("new best at iteration {i}")}
    param$accept[i] <- TRUE
    param$current_row[i] <- i
  } else {
    change <- param$log_post[i] - param$log_post[curr]
    param$accept_prob[i] <- exp(change)

    if (param$random[i] <= param$accept_prob[i]) {
      if (verbose) {cli_alert_warning("accept suboptimal at iteration {i}")}
      param$accept[i] <- TRUE
      param$current_row[i] <- i
    } else {
      if (verbose) {cli_alert_danger("reject suboptimal at iteration {i}")}
      param$accept[i] <- FALSE
      param$current_row[i] <- curr
    }
  }
}

param$parent <- dplyr::lag(param$current_row - 1)

# ------------------------------------------------------------------------------
# Use 250 iterations for warmup

warmup <- 250
warmup_data <-
  param %>%
  filter(iteration <= warmup) %>%
  mutate(
    Decision =
      case_when(
        better ~ "improvement",
        !better & accept ~ "acceptable",
        TRUE ~ "rejected"
      ),
    Decision = factor(Decision, levels = c("improvement", "acceptable", "rejected"))
  )

# ------------------------------------------------------------------------------
# Organize posterior sample

posterior <-
  param %>%
  filter(accept & iteration > warmup) %>%
  select(iteration, intercept = beta_0, slope = beta_1)

nrow(posterior)

# ------------------------------------------------------------------------------

save(warmup, param, tr_data, warmup_data, posterior, 
     file = "RData/logistic_bayes.RData")

# ------------------------------------------------------------------------------

if (!interactive()) {
  q("no")
}

