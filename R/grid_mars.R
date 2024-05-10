
library(tidymodels)

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
    prod_degree = 1:2,
    num_terms = 2:20)

# ------------------------------------------------------------------------------

grid_mars <- NULL

for (i in 1:nrow(combinations)) {
  mod_spec <- 
    mars(
      prod_degree = combinations$prod_degree[i],
      num_terms = combinations$num_terms[i],
      prune_method = "none"
    ) %>% 
    set_mode("classification")
  mod_fit <- fit(mod_spec, class ~ ., data = example_train)
  mod_grid <- 
    augment(mod_fit, demo_grid) %>% 
    mutate(
      prod_degree = combinations$prod_degree[i],
      num_terms = combinations$num_terms[i]
    )
  grid_mars <- bind_rows(grid_mars, mod_grid)
}

# save(grid_mars, file = "/Users/max/content/website/RData/grid_mars.RData", compress = TRUE)
