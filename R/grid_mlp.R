library(tidymodels)
library(discrim)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

load("RData/example_class.RData")

x <- seq(-1, 1, length.out = 100)
demo_grid <- crossing(predictor_1 = x, predictor_2 = x)

# ------------------------------------------------------------------------------

combinations <- 
  crossing(
    activation = c("tanh", "relu", "celu"),
    learn_rate = -3:-1,
    penalty = -4:-1,
    hidden_units = 4:15,
    stop_iter = c(5, Inf)
  )

# ------------------------------------------------------------------------------

grid_mlp <- NULL

for (i in 1:nrow(combinations)) {
  mod_spec <- 
    mlp(
      penalty = !!10^combinations$penalty[i],
      learn_rate = !!10^combinations$learn_rate[i],
      activation = !!combinations$activation[i],
      hidden_units = !!combinations$hidden_units[i],
      epochs = 500
    ) %>% 
    set_mode("classification") %>% 
    set_engine("brulee", stop_iter = !!combinations$stop_iter[i])
  
  set.seed(1)
  mod_fit <- try(fit(mod_spec, class ~ ., data = example_train))
  
  # print(mod_fit)
  
  if (!inherits(mod_fit, "try-error")) {
    mod_grid <- 
      augment(mod_fit, demo_grid) %>% 
      mutate(
        penalty = combinations$penalty[i],
        learn_rate = combinations$learn_rate[i],
        activation = combinations$activation[i],
        hidden_units = combinations$hidden_units[i],
        stop_iter = combinations$stop_iter[i]
      )
    grid_mlp <- bind_rows(grid_mlp, mod_grid)
  }
  
}

# Failed models

tibble::tribble(
  ~activation, ~learn_rate, ~penalty, ~hidden_units, ~stop_iter,
  "relu",         -3L,      -4L,            9L,          5,
  "relu",         -3L,      -4L,            9L,        Inf,
  "relu",         -3L,      -3L,            9L,          5,
  "relu",         -3L,      -3L,            9L,        Inf,
  "relu",         -2L,      -3L,            5L,          5,
  "relu",         -2L,      -3L,            5L,        Inf,
  "relu",         -2L,      -1L,            5L,          5,
  "relu",         -2L,      -1L,            5L,        Inf,
  "tanh",         -4L,      -3L,            4L,          5,
  "tanh",         -4L,      -3L,            4L,        Inf
)

# save(grid_mlp, file = "/Users/max/content/website/mlpta/grid_mlp.mlpta", compress = TRUE)
