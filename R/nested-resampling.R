library(tidymodels)
library(bonsai)
library(nestedtune)
library(mirai)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)


num_workers <- parallel::detectCores()
daemons(num_workers)

# ------------------------------------------------------------------------------

source("R/setup_two_class_example.R")

set.seed(943)
sim_tr <- sim_logistic(2000, sim_f)

set.seed(14)
sim_rs <- vfold_cv(sim_tr)

set.seed(14)
sim_nested_rs <- nested_resamples(
  sim_tr,
  outside = vfold_cv(),
  inside = vfold_cv()
)

# ------------------------------------------------------------------------------

one_dim_spec <-
  boost_tree(learn_rate = tune(), trees = 500) %>%
  set_mode("classification") %>%
  set_engine("lightgbm")

one_dim_wflow <-
  workflow() %>%
  add_model(one_dim_spec) %>%
  add_formula(class ~ A + B)

one_dim_param <-
  one_dim_wflow %>%
  extract_parameter_set_dials() %>%
  update(learn_rate = learn_rate(c(-3, -1)))

one_dim_reg <- grid_regular(one_dim_param, levels = 100)

# ------------------------------------------------------------------------------

grid_time <-
  system.time({
    set.seed(1)
    grid_res <-
      one_dim_wflow %>%
      tune_grid(
        resamples = sim_rs,
        metrics = metric_set(brier_class),
        grid = one_dim_reg
      )
  })

grid_nest_time <-
  system.time({
    set.seed(1)
    nest_grid_res <-
      one_dim_wflow %>%
      nested_tune_grid(
        resamples = sim_nested_rs,
        metrics = metric_set(brier_class),
        grid = one_dim_reg
      )
  })

bo_time <-
  system.time({
    set.seed(1)
    bo_res <-
      one_dim_wflow %>%
      tune_bayes(
        resamples = sim_rs,
        metrics = metric_set(brier_class),
        initial = 3,
        iter = 10,
        param_info = one_dim_param
      )
  })

bo_nest_time <-
  system.time({
    set.seed(1)
    nest_bo_res <-
      one_dim_wflow %>%
      nested_tune_bayes(
        resamples = sim_nested_rs,
        metrics = metric_set(brier_class),
        initial = 3,
        iter = 20,
        param_info = one_dim_param
      )
  })

# ------------------------------------------------------------------------------

nest_grid_brier <- collect_metrics(nest_grid_res)
grid_brier <- show_best(grid_res, metric = "brier_class", n = 1)
opt_per_resample <-
  collect_metrics(grid_res, summarize = FALSE) |>
  slice_min(.estimate, by = id)
multiples <-
  opt_per_resample |>
  count(learn_rate) |>
  filter(n > 1) |>
  pluck("learn_rate") |>
  log10() |>
  signif(digits = 3)
lr_lab <- cli::pluralize(
  "There {?was/were} {length(multiples)} learning rate{?s} selected more than once: "
)
lr_lab <- paste0(
  lr_lab,
  knitr::combine_words(paste0("10<sup>", multiples, "</sup>")),
  "."
)
# ------------------------------------------------------------------------------

autoplot(grid_res) +
  labs(y = "Brier Score") +
  geom_vline(xintercept = grid_brier$learn_rate, lty = 3) +
  geom_rug(
    data = opt_per_resample,
    aes(x = learn_rate, y = NULL, col = id),
    sides = "b",
    show.legend = FALSE,
    linewidth = 2,
    alpha = 3 / 4
  )

# ------------------------------------------------------------------------------

nest_grid_lines <-
  nest_grid_res |>
  select(id, .inner_metrics) |>
  unnest(.inner_metrics)

nest_grid_best <-
  nest_grid_lines |>
  slice_min(mean, by = id)

nest_grid_std_error <-
  sd(nest_grid_best$mean) / sqrt(nrow(nest_grid_best))

nest_grid_outer_best <-
  collect_metrics(nest_grid_res, summarize = FALSE) |>
  select(id, outer = .estimate)

two_levels_wide <-
  inner_join(nest_grid_best, nest_grid_outer_best, by = "id") |>
  select(id, learn_rate, inner = mean, outer)

two_levels <-
  two_levels_wide |>
  pivot_longer(cols = c(inner, outer), names_to = "level", values_to = "brier")

brier_range <- extendrange(c(nest_grid_lines$mean, two_levels$brier))

# ------------------------------------------------------------------------------

p_trend <-
  nest_grid_lines |>
  ggplot(aes(learn_rate, mean, col = id)) +
  geom_line(show.legend = FALSE, linewidth = 1, alpha = 1 / 3) +
  scale_x_log10() +
  labs(x = "Learning Rate", y = "Brier Score") +
  geom_point(data = nest_grid_best, show.legend = FALSE) +
  ylim(brier_range) +
  theme(plot.margin = margin(r = 0, unit = "pt"))

p_diff <-
  two_levels |>
  ggplot(aes(level, brier)) +
  geom_boxplot() +
  geom_point(alpha = 1 / 5) +
  ylim(brier_range) +
  labs(y = NULL, x = NULL) +
  theme(
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    plot.margin = margin(l = 0, unit = "pt")
  )

p_trend + p_diff + plot_layout(widths = c(5, 1))

# ------------------------------------------------------------------------------

#debiased_grid <- debias_estimate(grid_res)
#debiased_bo <- debias_estimate(bo_res)

# ------------------------------------------------------------------------------

save(
  list = c(
    ls(pattern = "_res$"),
    ls(pattern = "_time$"),
    #    "debiased_grid",
    #    "debiased_bo",
    "num_workers"
  ),
  file = "~/github/website/RData/nested_res.RData"
)

# ------------------------------------------------------------------------------

if (!interactive()) {
  q("no")
}
