sim_f <- rlang::expr(-1 - 4 * A - 2 * B - 0.2 * A^2 + 1 * B^2)
sim_seq <- seq(-4, 4, length.out = 100)

sim_pred_grid <-
  tidyr::crossing(A = seq(-3, 3, length.out = 100), B = sim_seq) %>%
  dplyr::mutate(
    lp = rlang::eval_tidy(sim_f, data = .)
  )

set.seed(943)
sim_tr <- sim_logistic(200, sim_f)
sim_new <- sim_logistic(1000, sim_f)

set.seed(14)
sim_rs <- vfold_cv(sim_tr)

set.seed(14)
sim_nested_rs <- nested_cv(sim_tr, outside = vfold_cv(), inside = vfold_cv())
