
library(tidymodels)
library(gganimate)

# ------------------------------------------------------------------------------

tidymodels_prefer()
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

source("R/_common.R")

light_bg <- "#fcfefe"
dark_bg <- "#222"

# ------------------------------------------------------------------------------

load("RData/bayes_opt_calcs.RData")

# ------------------------------------------------------------------------------

set.seed(1)
grid_points <- 
  grid_points %>% 
  mutate(
    smoothed = stats::filter(mean, rep(1/3,3)),
    smoothed = if_else(is.na(smoothed), mean, smoothed),
    sampled = smoothed + rnorm(n(), sd = 1 / 2)
  )

set.seed(2)
bayes_points <- 
  bayes_points  %>% 
  mutate(sampled = mean + rnorm(n(), sd = 1 / 2)) 

bayes_iter <- 
  bayes_points %>% 
  filter(.iter > 0) %>% 
  slice_tail(n = 1, by = c(.iter))

  
# ------------------------------------------------------------------------------

grid_points  %>% 
  ggplot(aes(learn_rate, smoothed)) + 
  geom_line(linewidth = 1, alpha = 1 / 4) + 
  scale_x_log10()

# ------------------------------------------------------------------------------
# light mode

theme_set(theme_transparent())

set.seed(283)
p <- grid_points %>% 
  ggplot(aes(learn_rate)) + 
  geom_line(aes(y = smoothed), linewidth = 1, alpha = 1 / 4) + 
  geom_point(
    data = grid_points %>% slice(c(1, 50, 100)), 
    aes(y = sampled),
    cex = 3, pch = 1
  ) +
  geom_point(
    data = bayes_iter,
    aes(y = sampled),
    cex = 3
  ) +
  scale_x_log10() +
  transition_states(.iter, state_length = 10, transition_length = 4) +
  shadow_mark(alpha = 1 / 4) +
  labs(
    x = "Learning Rate",
    y = "Error", 
    title = "iteration: {closest_state}"
  )

animate(
  p,
  device = "png",
  detail = 5,
  height = 4.25,
  width = 6, 
  units = "in", 
  res = 150,
  renderer = magick_renderer(),
  duration = 15
)

anim_save("premade/anim_learn_rate.gif")


# ------------------------------------------------------------------------------
# dark mode

theme_set(dk_gif_thm)

set.seed(283)
p <- grid_points %>% 
  ggplot(aes(learn_rate)) + 
  geom_line(aes(y = smoothed), linewidth = 1, alpha = 1 / 4, col = "#F2EFE5") + 
  geom_point(
    data = grid_points %>% slice(c(1, 50, 100)), 
    aes(y = sampled),
    cex = 3, pch = 1, col = "#F2EFE5"
  ) +
  geom_point(
    data = bayes_iter,
    aes(y = sampled),
    cex = 3, col = "#F2EFE5"
  ) +
  scale_x_log10() +
  transition_states(.iter, state_length = 10, transition_length = 4) +
  shadow_mark(alpha = 1 / 4) +
  labs(
    x = "Learning Rate",
    y = "Error", 
    title = "iteration: {closest_state}"
  )


animate(
  p,
  device = "png",
  detail = 5,
  height = 4.25,
  width = 6, 
  units = "in", 
  res = 150,
  renderer = magick_renderer(),
  duration = 15
)

anim_save("premade/anim_learn_rate_dark.gif")


