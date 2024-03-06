
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
    neighbors = seq(1, 21, by = 2),
    weight_func = c("rectangular", "triangular", "inv"),
    dist_power = seq(0.5, 2, by = 0.25))

# ------------------------------------------------------------------------------

grid_knn <- NULL

for (i in 1:nrow(combinations)) {
  mod_spec <- 
    nearest_neighbor(
      neighbors = combinations$neighbors[i],
      weight_func = combinations$weight_func[i],
      dist_power = combinations$dist_power[i]
    ) %>% 
    set_mode("classification")
  mod_fit <- fit(mod_spec, class ~ ., data = demo_tr)
  mod_grid <- 
    predict(mod_fit, demo_grid, type = "prob") %>% 
    select(.pred_A) %>% 
    bind_cols(demo_grid) %>% 
    mutate(
      neighbors = combinations$neighbors[i],
      weight_func = combinations$weight_func[i],
      dist_power = combinations$dist_power[i]
    )
  grid_knn <- bind_rows(grid_knn, mod_grid)
}

save(grid_knn, file = "/Users/max/content/website/RData/grid_knn.RData", compress = TRUE)
