library(RANN)

train_minority <-
  myopia_smol_formatted |>
  filter(class == "yes")

scaled_train <-
  recipe(class ~ ., data = myopia_smol_formatted) |>
  step_normalize(all_predictors()) |>
  prep() |>
  bake(new_data = NULL)

scaled_train_minority <-
  scaled_train |>
  filter(class == "yes")


graph <- nn2(
  scaled_train_minority |> select(-class) |> as.matrix(),
  k = neighbors
)

# ------------------------------------------------------------------------------

train_minority |>
  add_rowindex() |>
  filter(`axial length` > 23.5) |>
  slice_min(`spherical equivalent refraction`) |>
  pluck(".row")

selected_ind <- 38
neighbors <- 5
selected_neighbor <- 4

smote_base <-
  myopia_smol_formatted |>
  ggplot(aes(`spherical equivalent refraction`, y = `axial length`)) +
  geom_point(aes(col = class), alpha = 1 / 5) +
  lims(x = c(-0.7, 0.1), y = c(23.2, 24))

p <- smote_base

for (i in 1:neighbors) {
  new_ind <- graph$nn.idx[selected_ind, i]

  tmp <-
    train_minority |>
    slice(selected_ind) |>
    bind_cols(
      train_minority |>
        slice(new_ind) |>
        select(ser = `spherical equivalent refraction`, al = `axial length`)
    )
  if (i == selected_neighbor) {
    new_frame <- tmp
  }

  p <-
    p +
    geom_segment(
      data = tmp,
      aes(xend = ser, yend = al)
    ) +
    geom_point(data = tmp, aes(ser, y = al, col = class))
}

p +
  geom_point(
    data = train_minority |> slice(selected_ind),
    aes(col = class),
    alpha = 1,
    cex = 2
  )

# ------------------------------------------------------------------------------

new_ind <- graph$nn.idx[selected_ind, selected_neighbor]

myopia_smol_formatted |>
  ggplot(aes(`spherical equivalent refraction`, y = `axial length`)) +
  geom_point(aes(col = class), alpha = 1 / 2) +
  lims(x = c(-0.7, 0.0), y = c(23.2, 23.9)) +
  geom_segment(
    data = new_frame,
    aes(
      x = `spherical equivalent refraction`,
      xend = `spherical equivalent refraction`,
      y = `axial length`,
      yend = al
    ),
    lty = 2
  ) +
  geom_segment(
    data = new_frame,
    aes(x = ser, xend = ser, y = `axial length`, yend = al),
    lty = 2
  ) +
  geom_segment(
    data = new_frame,
    aes(
      x = `spherical equivalent refraction`,
      xend = ser,
      y = `axial length`,
      yend = `axial length`
    ),
    lty = 2
  ) +
  geom_segment(
    data = new_frame,
    aes(x = `spherical equivalent refraction`, xend = ser, y = al, yend = al),
    lty = 2
  ) +
  geom_segment(
    data = new_frame,
    aes(xend = ser, yend = al),
    alpha = 1 / 5,
    arrow = arrow(length = unit(0.3, "cm"), type = "closed")
  ) +
  geom_point(
    data = new_frame,
    aes(x = `spherical equivalent refraction`, y = `axial length`, col = class),
    cex = 2
  ) +
  geom_point(data = new_frame, aes(ser, y = al, col = class), cex = 2)
