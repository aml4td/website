# pak::pak(c("topepo/C5.0@save-weights"), ask = FALSE)

library(tidymodels)
library(C50)

load("RData/forested_data.RData")

set.seed(28267)
fit <- C5.0(forested_train |> select(-class), forested_train$class, trials = 500)

repredict <-
  predict(fit, forested_train, type = "prob") |>
  bind_cols(forested_train |> select(class)) |>
  add_rowindex()

indicies <-
  repredict |>
  mutate(probability = 0.95, diff = abs(probability - Yes)) |>
  slice_min(diff, n = 1) |>
  select(probability, .row) |>
  bind_rows(
    repredict |>
      mutate(probability = 0.50, diff = abs(probability - Yes)) |>
      slice_min(diff, n = 1) |>
      select(probability, .row)
  )

set.seed(28267)
refit <- C5.0(
  forested_train |> select(-class),
  forested_train$class,
  trials = 500,
  trace_rows = indicies$.row
)


c5_weights <-
  indicies |>
  rename(row = .row) |>
  full_join(refit$weight_trace, by = "row") |>
  filter(probability == 0.95) |>
  mutate(
    Prediction = ifelse(correct, "Correct", "Incorrect"),
    Prediction = ifelse(trial == 1, "Initial", Prediction),
    Prediction = factor(Prediction, levels = c("Initial", "Correct", "Incorrect"))
  )

save(c5_weights, file = "RData/c5_weights.RData")

c5_weights |>
  ggplot(aes(trial, weight)) +
  geom_line(alpha = 1 / 6) +
  geom_point(cex = 1, aes(col = Prediction)) +
  scale_color_manual(values = c("black", "#95C65CFF", "#BE3428FF")) +
  labs(x = "Boosting Iteration", y = "Case Weight") +
  theme_bw()


