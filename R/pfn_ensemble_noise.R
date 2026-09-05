library(tidymodels)

ensemble_estimates <- NULL
est_seq <- (1:5) * 2
est_seq_chr <- gsub(" ", "0", format(est_seq))
for (i in seq_along(est_seq)) {
  n <- est_seq[i]
  ch <- est_seq_chr[i]
  url <- glue::glue("delimited/per_estimator_logits_long_n{ch}.csv")
  ensemble_reps <-
    readr::read_csv(url) |>
    select(.row = row_id, estimate_index = estimator, class = true, p_Yes) |>
    mutate(estimate_index = estimate_index + 1, num_estimators = n)
  ensemble_estimates <- bind_rows(ensemble_estimates, ensemble_reps)
}

ensemble_estimates <-
  ensemble_estimates |>
  mutate(
    .row = factor(gsub(" ", "0", format(.row))),
    logit = binomial()$linkfun(p_Yes)
  )

save(ensemble_estimates, file = "RData/ensemble_estimates.RData")

# set.seed(382)
# selected_rows <-
#  ensemble_estimates |>
#  mutate(group = ntile(logit, 10)) |>
#  slice_sample(n = 1, by = group) |>
#  select(.row)
#
# ensemble_estimates |>
#  inner_join(selected_rows, by = ".row") |>
#  mutate(.row = reorder(.row, logit)) |>
#  ggplot(aes(estimate_index, logit, col = class, group = .row)) +
#  geom_jitter(cex = 1/2) +
#  # geom_smooth() +
#  facet_wrap(~ .row)
#
# ensemble_estimates |>
#  filter(.row == "0068") |>
#  ggplot(aes(estimate_index, logit, col = estimate_index, group = .row)) +
#  geom_jitter(width = .1, height = .01, alpha = 1/2, cex = 2) +
#  scale_x_continuous(breaks = (1:5) * 2)
#
#
# ensemble_estimates |>
#  filter(.row == "0068") |>
#  summarise(
#   mean = mean(logit),
#   sd = sd(logit),
#   std_err = sd / sqrt(length(logit)),
#   .by = c(num_estimators)
#  ) |>
#  ggplot(aes(num_estimators, mean, size = sd)) +
#  geom_point()
#
# ensemble_estimates |>
#  summarise(
#   mean = mean(logit),
#   sd = sd(logit),
#   std_err = sd / sqrt(length(logit)),
#   .by = c(.row, num_estimators)
#  ) |>
#  ggplot(aes(mean, sd)) +
#  geom_point() +
#  geom_smooth() +
#  facet_wrap(~ num_estimators)
#
# ensemble_estimates |>
#  summarise(
#   mean = mean(logit),
#   sd = sd(logit),
#   std_err = sd / sqrt(length(logit)),
#   .by = c(.row, num_estimators)
#  ) |>
#  mutate(
#   `# Estimators` = format(num_estimators)
#  ) |>
#  ggplot(aes(mean, sd, col = `# Estimators`)) +
#  geom_line(
#   stat = "smooth",
#   se = FALSE,
#   method = "loess",
#   formula = y ~ x,
#   linewidth = 1.2,
#   alpha = 3 / 4,
#   span = 1 / 2
#  ) +
#  theme_bw() +
#  scale_color_viridis_d() +
#  labs(x = "Mean Logit", y = "Logit Std. Dev", color = "# Estimators")
