library(tidymodels)

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
    penalty = seq(-3, 0, by = 0.5),
    mixture = c(0, 1/4, 1/2, 3/4, 1),
    x1 = c(0, 5, 10, 20),
    x2 = c(0, 5, 10, 20)
  )

# ------------------------------------------------------------------------------

grid_glmnet <- NULL

for (i in 1:nrow(combinations)) {
  mod_spec <- 
    logistic_reg(
      penalty = 10^combinations$penalty[i], mixture = combinations$mixture[i]
    ) %>% 
    set_mode("classification") %>% 
    set_engine("glmnet")
  rec <- 
    recipe(class ~ ., data = example_train) %>% 
    step_interact(~ predictor_1:predictor_1)
  if (combinations$x1[i] > 1) {
    rec <- 
      rec %>% 
      step_spline_natural(predictor_1, deg_free = combinations$x1[i])
  }
  if (combinations$x2[i] > 1) {
    rec <- 
      rec %>% 
      step_spline_natural(predictor_2, deg_free = combinations$x2[i])
  }
  # rec <- rec %>% step_normalize(all_predictors())
  mod_wflow <- 
    workflow() %>% 
    add_model(mod_spec) %>% 
    add_recipe(rec)
  
  mod_fit <- fit(mod_wflow, data = example_train)
  mod_grid <- 
    augment(mod_fit, demo_grid) %>% 
    mutate(
      penalty = round(combinations$penalty[i], 1),
      mixture = round(combinations$mixture[i], 2),
      x1 = combinations$x1[i],
      x2 = combinations$x2[i]
    )
  grid_glmnet <- bind_rows(grid_glmnet, mod_grid)
}


save(grid_glmnet, file = "RData/grid_glmnet.RData", compress = TRUE)
