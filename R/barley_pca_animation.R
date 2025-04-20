library(tidymodels)
library(bestNormalize)
library(gganimate)
library(viridis)
library(magick)

# ------------------------------------------------------------------------------

source("R/setup_chemometrics.R")
source("R/_common.R")

# ------------------------------------------------------------------------------

light_bg <- "#fcfefe"
dark_bg <- "#222"

# ------------------------------------------------------------------------------

barley_pre_pca_rec <-
  recipe(barley ~ ., 
         data = barley_train %>% select(wvlgth_001, wvlgth_050, barley)) %>%
  step_zv(all_predictors()) %>%
  step_orderNorm(all_numeric_predictors()) %>% 
  prep()

barley_val_normed <- 
  barley_pre_pca_rec %>% 
  bake(barley_val)

barley_val_cor <- round(cor(barley_val_normed)[1,2], 2)

barley_pca_coefs <- 
  barley_pre_pca_rec %>% 
  step_pca(all_predictors(), num_comp = 2, id = "pca") %>% 
  prep() %>% 
  tidy(id = "pca")

# ------------------------------------------------------------------------------
# rotation math

rotate <- function(df, angle) {
  mat <- as.matrix(df[, 1:2])
  rot <- diag(rep(1, 2))
  theta <- pi * angle / 180
  rot[1, 1] <- cos(theta)
  rot[2, 2] <- cos(theta)
  rot[1, 2] <- -sin(theta)
  rot[2, 1] <- sin(theta)
  result <- mat %*% rot
  colnames(result) <- colnames(df)[1:2]
  result <- as_tibble(result)
  result$angle <- angle
  # Angle is going clockwise
  result$angle2 <- 360 - angle  
  # Add other columns
  p <- ncol(df)
  if ( p > 2 ) {
    result <- dplyr::bind_cols(result, df[, 3:p])
  }
  result
}

# ------------------------------------------------------------------------------
# compute the rotation initially across a set of angles

orig_angles <- seq(0, 360, length = 100)

rotations <-
  map_dfr(orig_angles, ~ rotate(barley_val_normed, .x), .id = "state") %>%
  mutate(
    state = as.numeric(state),
    state2 = max(state) - state
  )


# Find the state/angles with maximal variance on the x-axis; these are the PCs
variances <- 
  rotations %>% 
  summarize(
    x_var = var(wvlgth_001), 
    .by = c(angle, angle2, state2)
  )
opt_variances <- 
  variances %>% 
  slice_max(x_var, n = 2) %>% 
  mutate()

opt_angles <- 
  opt_variances %>% 
  pluck("angle") %>% 
  sort()

# ------------------------------------------------------------------------------

barley_val_normed %>% 
  ggplot(aes(wvlgth_001, wvlgth_050, col = barley)) + 
  geom_point() +
  coord_obs_pred()

rotations %>% 
  filter(state2 == opt_variances$state2[1]) %>% 
  ggplot(aes(wvlgth_001, wvlgth_050, col = barley)) + 
  geom_point() +
  coord_obs_pred()

rotations %>% 
  filter(state2 == opt_variances$state2[2]) %>% 
  ggplot(aes(wvlgth_001, wvlgth_050, col = barley)) + 
  geom_point() +
  coord_obs_pred()

# ------------------------------------------------------------------------------

# Redo angles with replicates that indicate pauses in the animation
angles <- c(rep(0, 10), rep(opt_angles[1], 9), rep(opt_angles[2], 9), orig_angles, 
            rep(360, 10))
angles <- sort(angles)

angles_lab <- round(min(opt_variances$angle2), 0)
angles_lab <- c(angles_lab, angles_lab + 180)
angles_txt <- paste0("maximum variance (", angles_lab, " degree rotation)")

# redo with pauses
rotations <-
  map_dfr(angles, ~ rotate(barley_val_normed, .x), .id = "state") %>%
  mutate(
    state = as.numeric(state),
    state2 = max(state) - state
    )

ranges <-
  rotations %>%
  distinct(angle, state2) %>%  
  mutate(
    note = ifelse(angle == 0 | angle == 360, "original data (zero degree rotation) ", ""),
    note = ifelse(angle == opt_angles[1], angles_txt[2], note),
    note = ifelse(angle == opt_angles[2], angles_txt[1], note),
    note_x = -.5, note_y = 4
  )

# ------------------------------------------------------------------------------
# make the animation - light mode

theme_set(theme_transparent())

pca_animation <-
  ggplot(rotations, aes(x = wvlgth_001, y = wvlgth_050)) +
  geom_text(data = ranges, aes(x = note_x, y = note_y, label = note)) +
  geom_point(aes(col = barley), alpha = 1 / 3, show.legend = FALSE) +
  transition_states(state2) +
  labs(x = "Dimension 1", y = "Dimension 2", title = "(b)") +
  enter_fade() +
  exit_shrink() +
  ease_aes('sine-in-out') +
  scale_color_viridis(option = "viridis")

anim <-
  gganimate::animate(
    pca_animation,
    detail = 5,
    width = 750,
    height = 750,
    res = 200,
    renderer = magick_renderer()
  )

anim

anim_save("premade/anime_barley_pca.gif")

# ------------------------------------------------------------------------------
# make the animation - dark mode

theme_set(dk_gif_thm)

pca_animation_dark <-
  ggplot(rotations, aes(x = wvlgth_001, y = wvlgth_050)) +
  geom_text(data = ranges, aes(x = note_x, y = note_y, label = note), col = "#adb5bd") +
  geom_point(aes(col = barley), alpha = 1 / 3, show.legend = FALSE) +
  transition_states(state2) +
  labs(x = "Dimension 1", y = "Dimension 2", title = "(b)") +
  enter_fade() +
  exit_shrink() +
  ease_aes('sine-in-out') +
  scale_color_viridis(option = "viridis")

anim <-
  gganimate::animate(
    pca_animation_dark,
    detail = 5,
    width = 750,
    height = 750,
    res = 200,
    renderer = magick_renderer(),
    bg = "#222"
  )

anim

anim_save("premade/anime_barley_pca_dark.gif")

# ------------------------------------------------------------------------------

save(barley_val_cor, barley_pca_coefs, opt_variances, file = "RData/barley_2d_pca_.RData")

