library(tidymodels)
library(discrim)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

load("RData/example_class.RData")

x <- seq(-1, 1, length.out = 60)
demo_grid <- crossing(predictor_1 = x, predictor_2 = x)

# ------------------------------------------------------------------------------

combinations <- 
  crossing(
    activation = c("tanh", "relu", "gelu"),
    learn_rate = -3:-1,
    penalty = c(0, -5:-1),
    hidden_units = seq(2, 50, by = 5)
  )

# ------------------------------------------------------------------------------

grid_mlp <- NULL

actual_epochs <- rep(NA_integer_, nrow(combinations))

for (i in 1:nrow(combinations)) {
  if (i %% 50 == 0) {
    cli::cli_inform("iteration {i} of {nrow(combinations)}\n")
  }
  
  penalty <- ifelse(combinations$penalty[i] == 0, 0, 10^combinations$penalty[i])
  mod_spec <- 
    mlp(
      penalty = !!penalty,
      learn_rate = !!10^combinations$learn_rate[i],
      activation = !!combinations$activation[i],
      hidden_units = !!combinations$hidden_units[i],
      epochs = 500
    ) %>% 
    set_mode("classification") %>% 
    set_engine("brulee", stop_iter = 5)
  
  set.seed(1)
  mod_fit <- try(fit(mod_spec, class ~ ., data = example_train))
  
  if (!inherits(mod_fit, "try-error")) {
    mod_grid <- 
      augment(mod_fit, demo_grid) %>% 
      mutate(
        penalty = combinations$penalty[i],
        learn_rate = combinations$learn_rate[i],
        activation = combinations$activation[i],
        hidden_units = combinations$hidden_units[i]
      )
    grid_mlp <- bind_rows(grid_mlp, mod_grid)

    actual_epochs[i] <- length(mod_fit$fit$loss)
    
  } else {
    cli::cli_inform("    x @ {i}\n")
  }
  
}

# ------------------------------------------------------------------------------
# Failed models

good_config <- 
  grid_mlp %>% 
  distinct(activation, learn_rate, penalty, hidden_units)

anti_join(combinations, good_config, 
          by = c("activation", "learn_rate", "penalty", "hidden_units"))

# ------------------------------------------------------------------------------
# early stopping mostly with high learning rates

combinations$actual <- actual_epochs
combinations %>% 
  ggplot(aes(hidden_units, actual, col = activation)) + 
  geom_point() + 
  facet_wrap(~ learn_rate)



save(grid_mlp, actual_epochs, file = "RData/grid_mlp.RData", compress = TRUE)

