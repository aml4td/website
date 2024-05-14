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
  mod_fit <- fit(mod_spec, class ~ ., data = example_train)
  mod_grid <- 
    augment(mod_fit, demo_grid) %>% 
    mutate(
      neighbors = combinations$neighbors[i],
      weight_func = combinations$weight_func[i],
      dist_power = combinations$dist_power[i]
    )
  grid_knn <- bind_rows(grid_knn, mod_grid)
}

save(grid_knn, file = "RData/grid_knn.RData", compress = TRUE)

