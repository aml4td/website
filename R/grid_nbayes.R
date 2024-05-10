
library(tidymodels)
library(discrim)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

x <- seq(-1, 1, length.out = 100)
demo_grid <- crossing(predictor_1 = x, predictor_2 = x)

# ------------------------------------------------------------------------------

combinations <- tibble(smoothness = seq(.25, 2, by = .25))

# ------------------------------------------------------------------------------

grid_nbayes <- NULL

for (i in 1:nrow(combinations)) {
  mod_spec <- 
    naive_Bayes(
      smoothness = combinations$smoothness[i]
    ) %>% 
    set_mode("classification")
  mod_fit <- fit(mod_spec, class ~ ., data = example_train)
  mod_grid <- 
    predict(mod_fit, demo_grid, type = "prob") %>% 
    select(.pred_event) %>% 
    bind_cols(demo_grid) %>% 
    mutate(
      smoothness = combinations$smoothness[i]
    )
  grid_nbayes <- bind_rows(grid_nbayes, mod_grid)
}

save(grid_nbayes, file = "/Users/max/content/website/RData/grid_nbayes.RData", compress = TRUE)
