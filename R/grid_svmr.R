
library(tidymodels)
library(kernlab)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

x <- seq(-1, 1, length.out = 100)
demo_grid <- crossing(predictor_1 = x, predictor_2 = x)

x <- as.matrix(example_train[, -3])
# log10(kernlab::sigest(x, frac = 1)) # to gauge rbf_sigma below

# ------------------------------------------------------------------------------

combinations <- 
  crossing(
    # in log units: 
    cost = seq(5, 25, by = 1),
    rbf_sigma = seq(-5, 2, by = 1)) # from kernlab::sigest

grid_svmr <- NULL

mat_grid <- as.matrix(demo_grid)

for (i in 1:nrow(combinations)) {

  kern <- rbfdot(sigma = 10^combinations$rbf_sigma[i])
  mod_fit <- ksvm(x, y = example_train$class, scaled = FALSE, 
                  C = 2^combinations$cost[i],
                  kernel = kern)
  
  mod_grid <- demo_grid
  mod_grid$pred <- predict(mod_fit, mat_grid, type = "decision")[,1]
  mod_grid <- 
    mod_grid %>% 
    mutate(
      cost = combinations$cost[i],
      rbf_sigma = combinations$rbf_sigma[i],
      .pred_class = predict(mod_fit, mat_grid, type = "response")
    )
  grid_svmr <- bind_rows(grid_svmr, mod_grid)
}

# save(grid_svmr, file = "/Users/max/content/website/RData/grid_svmr.RData", compress = TRUE)
