library(tidymodels)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

# load("RData/example_class.RData")

x <- seq(-1, 1, length.out = 100)
demo_grid <- crossing(predictor_1 = x, predictor_2 = x)

# ------------------------------------------------------------------------------

combinations <- 
  crossing(
    cost_complexity = seq(-4, -1, by = 0.5),
    min_n = (1:10) * 4,
    tree_depth = 1:10)

# ------------------------------------------------------------------------------

grid_cart <- NULL

for (i in 1:nrow(combinations)) {
  mod_spec <- 
    decision_tree(
      cost_complexity = 10^combinations$cost_complexity[i],
      min_n = combinations$min_n[i],
      tree_depth = combinations$tree_depth[i]
    ) %>% 
    set_mode("classification")
  mod_fit <- fit(mod_spec, class ~ ., data = example_train)
  mod_grid <- 
    augment(mod_fit, demo_grid) %>% 
    mutate(
      cost_complexity = combinations$cost_complexity[i],
      min_n = combinations$min_n[i],
      tree_depth = combinations$tree_depth[i]
    )
  grid_cart <- bind_rows(grid_cart, mod_grid)
}

# save(grid_cart, file = "/Users/max/content/website/RData/grid_cart.RData", compress = TRUE)
