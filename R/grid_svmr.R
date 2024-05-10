
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
# log10(kernlab::sigest(x, frac = 1))

# ------------------------------------------------------------------------------

combinations <- 
  crossing(
    cost = 2^seq(-1, 15, by = 0.5),
    rbf_sigma = 10^seq(-1, 0.5, by = 0.25)) # from kernlab::sigest


grid_svmr <- NULL

mat_grid <- as.matrix(demo_grid)

for (i in 1:nrow(combinations)) {

  kern <- rbfdot(sigma = combinations$rbf_sigma[i])
  mod_fit <- ksvm(x, y = example_train$class, scaled = FALSE, 
                  C = combinations$cost[i],
                  kernel = kern)
  
  mod_grid <- demo_grid
  mod_grid$pred <- predict(mod_fit, mat_grid, type = "decision")[,1]
  mod_grid <- 
    mod_grid %>% 
    mutate(
      cost = log2(combinations$cost[i]),
      rbf_sigma = log10(combinations$rbf_sigma[i])
    )
  grid_svmr <- bind_rows(grid_svmr, mod_grid)
}

save(grid_svmr, file = "/Users/max/content/website/RData/grid_svmr.RData", compress = TRUE)
