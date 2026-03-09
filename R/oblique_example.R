library(tidymodels)
# pak::pak(c("cran/oblique.tree"), ask = FALSE)
library(oblique.tree)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

set.seed(283)
dat <- sim_logistic(500, ~ .1 + 5 * A - 5 * B , corr = .7)

dat |>
  ggplot(aes(A, B, col = class)) +
  geom_point(alpha = 1/2) +
  coord_equal()

# ------------------------------------------------------------------------------

cart_fit <-
  decision_tree(mode = "classification") |>
  fit(class ~ ., data = dat)


x_seq <- seq(-3, 3, length.out = 100)
grid <- crossing(A = x_seq, B = x_seq)

cart_pred <- augment(cart_fit, grid) |> dplyr::mutate(split = "Rectanular")

# cart_pred |>
#   ggplot(aes(A, B)) +
#   geom_point(data = dat, aes(col = class), alpha = 1 / 2) +
#   geom_contour(aes(z = .pred_one), breaks = 1/2, col = "black", linewidth = 1) +
#   coord_fixed() +
#   labs(title = "Decision Tree")

cart_nodes <- sum(cart_fit$fit$frame[, "var"] == "<leaf>")

# ------------------------------------------------------------------------------


set.seed(181)
obl_fit <-
  oblique.tree(
    class ~ .,
    data = dat,
    oblique.splits	= "only",
    control = tree.control(nobs = nrow(dat), minsize = 500)
  )

obl_pred <- grid
obl_pred$class <- dat$class[1]
obl_pred$.pred_one <- predict(obl_fit, obl_pred)[,1]
obl_pred$split <- "Oblique"

obl_print <- capture.output(print(obl_fit))
obl_print <- obl_print[grepl("2)", obl_print, fixed = TRUE)]
obl_print <- strsplit(obl_print, split = " ")[[1]]
obl_eqn <- obl_print[grepl("<", obl_print, fixed = TRUE)]

# ------------------------------------------------------------------------------

orig_dat <-
  grid |>
  dplyr::mutate(split = "Data", .pred_one = runif(nrow(grid), max = .1))

oblique_example <-
  bind_rows(orig_dat, cart_pred, obl_pred) |>
  dplyr::mutate(split = factor(split, levels = c("Data", "Rectanular", "Oblique"))) |>
  select(-class)

# oblique_example |>
#   ggplot(aes(A, B)) +
#   geom_point(data = dat, aes(col = class), alpha = 1 / 2, cex = 3 / 4) +
#   geom_contour(
#     aes(z = .pred_one),
#     breaks = 1 / 2,
#     col = "black",
#     linewidth = 1
#   ) +
#   coord_fixed() +
#   facet_wrap( ~ split) +
#   scale_color_manual(values = c("#DF9ED4FF", "#3C4B99FF"))

save(oblique_example, cart_nodes, obl_eqn, file = "RData/oblique_example.RData")
