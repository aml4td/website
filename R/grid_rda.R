library(tidymodels)
library(discrim)

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
    frac_common_cov = seq(0, 1, by = .2),
    frac_identity = seq(0, 1, by = .2))

# ------------------------------------------------------------------------------

grid_rda <- NULL

for (i in 1:nrow(combinations)) {
  mod_spec <- 
    discrim_regularized(
      frac_common_cov = combinations$frac_common_cov[i],
      frac_identity = combinations$frac_identity[i]
    ) %>% 
    set_mode("classification")
  mod_fit <- fit(mod_spec, class ~ ., data = example_train)
  mod_grid <- 
    augment(mod_fit, demo_grid) %>% 
    mutate(
      frac_common_cov = combinations$frac_common_cov[i],
      frac_identity = combinations$frac_identity[i]
    )
  grid_rda <- bind_rows(grid_rda, mod_grid)
}


save(grid_rda, file = "RData/grid_rda.RData", compress = TRUE)
