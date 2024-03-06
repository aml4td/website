
library(tidymodels)

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

# ------------------------------------------------------------------------------

combinations <- 
  crossing(
    prod_degree = 1:2,
    num_terms = 2:10)

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
  mod_fit <- fit(mod_spec, class ~ ., data = demo_tr)
  mod_grid <- 
    predict(mod_fit, demo_grid, type = "prob") %>% 
    select(.pred_A) %>% 
    bind_cols(demo_grid) %>% 
    mutate(
      prod_degree = combinations$prod_degree[i],
      num_terms = combinations$num_terms[i]
    )
  grid_mars <- bind_rows(grid_mars, mod_grid)
}

save(grid_mars, file = "/Users/max/content/website/RData/grid_mars.RData", compress = TRUE)
