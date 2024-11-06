library(tidymodels)
library(measure)
library(modeldatatoo)

tidymodels_prefer()
conflicted::conflicts_prefer(recipes::update)

# ------------------------------------------------------------------------------

chimiometrie_2019 <-
  data_chimiometrie_2019()  %>%
  add_rowindex() %>%
  select(-soy_oil, -lucerne) %>%
  rename(.sample = .row)

barley_breaks <- (0:27) * 2

set.seed(101)
barley_split <- initial_validation_split(chimiometrie_2019, prop = c(0.7, 0.15),
                                         strata = barley)
barley_train <- training(barley_split)
barley_val <- validation(barley_split)
barley_test <- testing(barley_split)
barley_rs <- validation_set(barley_split)

# ------------------------------------------------------------------------------

tidymodels_prefer()

# ------------------------------------------------------------------------------

smoothing_only <- crossing(
  window_side = c(1, 3, 5),
  degree = c(1, 2, 5),
  differentiation_order = 0
) %>%
  filter(
    degree >= differentiation_order &
      (2 * window_side + 1) >= degree
  )

raw_plot_data <- smoothed_plot_data <- NULL
for (i in 1:nrow(smoothing_only)) {

  raw_data <-
    barley_train %>%
    filter(.sample == 2) %>%
    pivot_longer(cols = starts_with("wvlgth"),
                 names_to = "name",
                 values_to = ".measure") %>%
    mutate(
      .location = gsub("wvlgth_", "", name),
      .location = as.integer(.location)
    ) %>%
    filter(.location >= 500 + smoothing_only$window_side[i] &
            .location <= 550 - smoothing_only$window_side[i]) %>%
    mutate(
      `differentiation order` = smoothing_only$differentiation_order[i],
      `polynomial degree` = smoothing_only$degree[i],
      `window size` = 2 * smoothing_only$window_side[i] + 1,
      window = factor(`window size`)
    )
  raw_plot_data <- bind_rows(raw_plot_data, raw_data)

  smoothed_data <-
    recipe(barley ~ ., data = barley_train) %>%
    update_role(.sample, new_role = ".sample") %>%
    step_measure_input_wide(starts_with("wvlgth_")) %>%
    step_measure_savitzky_golay(
      differentiation_order = smoothing_only$differentiation_order[i],
      degree = smoothing_only$degree[i],
      window_side = smoothing_only$window_side[i]
    ) %>%
    step_measure_output_long() %>%
    prep() %>%
    bake(new_data = NULL) %>%
    mutate(
      `differentiation order` = smoothing_only$differentiation_order[i],
      `polynomial degree` = smoothing_only$degree[i],
      `window size` = 2 * smoothing_only$window_side[i] + 1,
      window = factor(`window size`)
    ) %>%
    filter(.sample == 2 & .location >= 490)

  smoothed_plot_data <- bind_rows(smoothed_plot_data, smoothed_data)

}

# ------------------------------------------------------------------------------

first_diff <- crossing(
  window_side = c(1, 3, 5),
  degree = c(1, 2, 5),
  differentiation_order = 1
) %>%
  filter(
    degree >= differentiation_order &
      (2 * window_side + 1) >= degree
  )

raw_diff_plot_data <- diff_plot_data <- NULL
for (i in 1:nrow(first_diff)) {

  raw_data <-
    barley_train %>%
    filter(.sample == 2) %>%
    pivot_longer(cols = starts_with("wvlgth"),
                 names_to = "name",
                 values_to = ".measure") %>%
    mutate(
      .location = gsub("wvlgth_", "", name),
      .location = as.integer(.location)
    ) %>%
    filter(.location >= 500 + smoothing_only$window_side[i] &
             .location <= 550 - smoothing_only$window_side[i]) %>%
    mutate(
      `differentiation order` = first_diff$differentiation_order[i],
      `polynomial degree` = first_diff$degree[i],
      `window size` = 2 * first_diff$window_side[i] + 1,
      window = factor(`window size`),
      .orig = .measure,
      .measure = .orig - dplyr::lag(.orig)
    )
  raw_diff_plot_data <- bind_rows(raw_diff_plot_data, raw_data)

  smoothed_data <-
    recipe(barley ~ ., data = barley_train) %>%
    update_role(.sample, new_role = ".sample") %>%
    step_measure_input_wide(starts_with("wvlgth_")) %>%
    step_measure_savitzky_golay(
      differentiation_order = first_diff$differentiation_order[i],
      degree = first_diff$degree[i],
      window_side = first_diff$window_side[i]
    ) %>%
    step_measure_output_long() %>%
    prep() %>%
    bake(new_data = NULL) %>%
    mutate(
      `differentiation order` = first_diff$differentiation_order[i],
      `polynomial degree` = first_diff$degree[i],
      `window size` = 2 * first_diff$window_side[i] + 1,
      window = factor(`window size`)
    ) %>%
    filter(.sample == 2 & .location >= 490)

  diff_plot_data <- bind_rows(diff_plot_data, smoothed_data)

}

save(smoothed_plot_data, raw_plot_data, diff_plot_data, raw_diff_plot_data,
     file = "RData/savitzky_golay_demo.RData")

# ------------------------------------------------------------------------------
cli::cli_rule("Reproducability")

sessioninfo::session_info()

if (!interactive()) {
  q("no")
}

