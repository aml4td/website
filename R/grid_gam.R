
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

combinations <- tibble(adjust_deg_free = seq(1, 2.5, by = .25))

# ------------------------------------------------------------------------------

grid_gam <- NULL

for (i in 1:nrow(combinations)) {
  mod_spec <- 
    gen_additive_mod(
      adjust_deg_free = combinations$adjust_deg_free[i], select_features = TRUE
    ) %>% 
    set_mode("classification")
  mod_fit <- fit(mod_spec, class ~ s(predictor_1) + s(predictor_2), 
                 data = example_train)
  mod_grid <- 
    augment(mod_fit, demo_grid) %>% 
    mutate(
      adjust_deg_free = combinations$adjust_deg_free[i]
    )
  grid_gam <- bind_rows(grid_gam, mod_grid)
}

save(grid_gam, file = "/Users/max/content/website/RData/grid_gam.RData", compress = TRUE)
