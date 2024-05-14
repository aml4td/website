library(tidymodels)
library(rules)

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
    trees = c(1, 10, 25, 50),
    min_n = c(2, 10, 25),
    penalty = -4:-1,
    learn_rate = -4:-1,
    tree_depth = 1:5
  )

# ------------------------------------------------------------------------------


grid_xrf <- NULL

for (i in 1:nrow(combinations)) {
  mod_spec <- 
    rule_fit(
      penalty = !!10^combinations$penalty[i],
      min_n = !!combinations$min_n[i],
      learn_rate = !!10^combinations$learn_rate[i],
      trees = !!combinations$trees[i],
      tree_depth = !!combinations$tree_depth[i]
    ) %>% 
    set_mode("classification")
  
  set.seed(1)
  mod_fit <- try(fit(mod_spec, class ~ ., data = example_train))
  
  # print(mod_fit)
  
  if (!inherits(mod_fit, "try-error")) {
    mod_grid <- 
      augment(mod_fit, demo_grid) %>% 
      mutate(
        penalty = combinations$penalty[i],
        min_n = combinations$min_n[i],
        learn_rate = combinations$learn_rate[i],
        trees = combinations$trees[i],
        tree_depth = combinations$tree_depth[i]
      )
    grid_xrf <- bind_rows(grid_xrf, mod_grid)
  }
  
}


# save(grid_xrf, file = "/Users/max/content/website/xrfta/grid_xrf.xrfta", compress = TRUE)
