
set.seed(3468)
sim_not_test <-
  sim_classification(2000) %>%
  bind_cols(
    sim_noise(2000, num_vars = 20, cov_type = "toeplitz", cov_param = 1 / 2)
  )
sim_test <-
  sim_classification(1000) %>%
  bind_cols(
    sim_noise(1000, num_vars = 20, cov_type = "toeplitz", cov_param = 1 / 2)
  )

set.seed(56923)
sim_rs <- validation_split(sim_not_test, prop = 0.5)
sim_train <- analysis(sim_rs$splits[[1]])
sim_val   <- assessment(sim_rs$splits[[1]])
