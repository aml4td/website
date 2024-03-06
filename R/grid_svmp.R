
library(tidymodels)
library(kernlab)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

load("/Users/max/content/website/RData/demo_data.RData")
load("/Users/max/content/website/RData/demo_grid.RData")

# ------------------------------------------------------------------------------

set.seed(986)
split <- initial_split(demo_data, prop = 2 / 3, strata = class)
demo_tr <- training(split)
demo_te <- testing(split)

x <- as.matrix(demo_tr[, -3])

# ------------------------------------------------------------------------------

combinations <- 
  crossing(
    cost = 2^seq(-1, 15, by = 0.5),
    degree = 1:4,
    scale_factor = 10^seq(-5, -1, by = 0.5))

# ------------------------------------------------------------------------------

grid_svmp <- NULL

mat_grid <- as.matrix(demo_grid)

for (i in 1:nrow(combinations)) {
  
  kern <- polydot(degree = combinations$degree[i], 
                  scale = combinations$scale_factor[i])
  mod_fit <- ksvm(x, y = demo_tr$class, scaled = FALSE, 
                  C = combinations$cost[i],
                  kernel = kern)
  
  mod_grid <- demo_grid
  mod_grid$pred <- predict(mod_fit, mat_grid, type = "decision")[,1]
  mod_grid <- 
    mod_grid %>% 
    mutate(
      cost = log2(combinations$cost[i]),
      degree = combinations$degree[i], 
      scale_factor = log10(combinations$scale_factor[i])
    )
  grid_svmp <- bind_rows(grid_svmp, mod_grid)
}

save(grid_svmp, file = "/Users/max/content/website/RData/grid_svmp.RData", compress = TRUE)
