# pak::pak(c("tidymodels/dials@constraints"), ask = FALSE)
# pak::pak(c("JamesHWade/measure@sg-parameters"), ask = FALSE)
# pak::pak(c("prospectr"), ask = FALSE)
library(tidymodels)
library(finetune)
library(future)
library(bestNormalize)
library(measure)
library(modeldatatoo)

tidymodels_prefer()
conflicted::conflicts_prefer(recipes::update)
plan("multisession")
options(future.globals.maxSize = 1.0 * 1e9)  ## 1.0 GB

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

reg_mtr <- metric_set(rmse)
num_iter <- 50

get_num_iter <- function(x) {
  library(tidymodels)
  iters <- 
    x %>% 
    extract_fit_engine() %>% 
    purrr::pluck("best_epoch")
  iters
}

# ------------------------------------------------------------------------------

barley_sg_rec <-
  recipe(barley ~ ., data = barley_train) %>%
  update_role(.sample, new_role = ".sample") %>%
  step_measure_input_wide(starts_with("wvlgth_")) %>%
  step_measure_savitzky_golay(
    differentiation_order = tune(),
    degree = tune(),
    window_side = tune()
  ) %>% 
  step_measure_output_wide(prefix = "x_") %>% 
  step_orderNorm(all_predictors())

mlp_spec <-
  mlp(
    hidden_units = tune(),
    activation =  tune(),
    penalty = tune(),
    learn_rate = tune(),
    epoch = 2000
  ) %>%
  set_mode("regression") %>%
  set_engine("brulee",
             stop_iter = tune(),
             mixture = tune(),
             rate_schedule = tune())

mlp_wflow <- workflow(barley_sg_rec, mlp_spec)

acts <-  c("tanh",   "relu",         "elu", "log_sigmoid")
sched <- c("none", "cyclic",  "decay_time")
mlp_param <-
  mlp_wflow %>%
  extract_parameter_set_dials() %>%
  update(
    hidden_units = hidden_units(c(2, 100)),
    activation = activation(acts),
    rate_schedule = rate_schedule(sched),
    learn_rate = learn_rate(c(-2, -1/2)),
    mixture = mixture(),
    degree = degree_int(c(1, 10)),
    window_side = window_side(c(1, 10))
  )

# filter length w must be greater than polynomial order p
# polynomial order p must be greater or equal to differentiation order m

mlp_param <- 
  mlp_param %>% 
  add_parameter_constraint(
    (2 * window_side) + 1 > degree & degree  >= differentiation_order 
  )


grid_size <- nrow(mlp_param) + 1
set.seed(230)
init_rnd <- 
  grid_random(mlp_param, size = floor(grid_size * 2)) %>% 
  slice_sample(n = grid_size)
init_sfd <- grid_space_filling(mlp_param, size = 20) # set to 20 to get 11 after constraint
nrow(init_sfd)

# ------------------------------------------------------------------------------

grid_ctrl <- control_grid(
	save_pred = TRUE,
	parallel_over = "everything",
	extract = get_num_iter
)

mlp_init_sfd_time <- system.time({
  set.seed(998)
  mlp_sfd_initial <-
    mlp_wflow %>%
    tune_grid(
      resamples = barley_rs,
      grid = init_sfd,
      metrics = reg_mtr,
      control = grid_ctrl
    )
})

iters_sfd_initial <- 
  mlp_sfd_initial %>% 
  collect_extracts() %>% 
  unnest(.extracts) %>% 
  rename(num_epochs = .extracts)

# ------------------------------------------------------------------------------

mlp_bo_time <- system.time({
  set.seed(684)
  mlp_sfd_bo <-
    mlp_wflow %>%
    tune_bayes(
      resamples = barley_rs,
      initial = mlp_sfd_initial,
      iter = num_iter,
      param_info = mlp_param,
      metrics = reg_mtr,
      control = control_bayes(
        save_pred = TRUE,
        no_improve = Inf,
        verbose_iter = TRUE,
        verbose = FALSE,
        save_workflow = TRUE
      )
    )
})

set.seed(74)
mlp_sfd_bo_ci <- 
  int_pctl(mlp_sfd_bo, times = 5000, alpha = 0.1) %>%
  mutate(method = "Bayesian Optimzation")

mlp_sfd_bo_met <- collect_metrics(mlp_sfd_bo)
mlp_sfd_bo_best <- integer(0)
mlp_sfd_bo_rmse <- 
  mlp_sfd_bo_met %>% 
  filter(.iter == 0) %>% 
  slice_min(mean) %>% 
  pluck("mean")

for (i in 1:max(mlp_sfd_bo_met$.iter)) {
  curr_rmse <- 
    mlp_sfd_bo_met %>% 
    filter(.iter == i) %>% 
    pluck("mean")
  if (curr_rmse < mlp_sfd_bo_rmse) {
    mlp_sfd_bo_rmse <- curr_rmse
    mlp_sfd_bo_best <- c(mlp_sfd_bo_best, i)
  }
}

iters_sfd_bo <- 
  mlp_sfd_bo %>% 
  collect_extracts() %>% 
  unnest(.extracts) %>% 
  rename(num_epochs = .extracts)

# ------------------------------------------------------------------------------

mlp_sa_time <- system.time({
  set.seed(50)
  mlp_sfd_sa <-
    mlp_wflow %>%
    tune_sim_anneal(
      resamples = barley_rs,
      initial = mlp_sfd_initial,
      iter = num_iter,
      param_info = mlp_param,
      metrics = reg_mtr,
      control = control_sim_anneal(
        save_pred = TRUE,
        no_improve = Inf,
        verbose_iter = TRUE,
        verbose = FALSE,
        save_workflow = TRUE,
        save_history = TRUE,
        extract = get_num_iter
      )
    )
})

set.seed(74)
mlp_sfd_sa_ci <- 
  int_pctl(mlp_sfd_sa, times = 5000, alpha = 0.1) %>%
  mutate(method = "Simulated Annealing")

mlp_sfd_sa_met <- collect_metrics(mlp_sfd_sa)
mlp_sfd_sa_best <- integer(0)
mlp_sfd_sa_rmse <- 
  mlp_sfd_sa_met %>% 
  filter(.iter == 0) %>% 
  slice_min(mean) %>% 
  pluck("mean")

for (i in 1:max(mlp_sfd_sa_met$.iter)) {
  curr_rmse <- 
    mlp_sfd_sa_met %>% 
    filter(.iter == i) %>% 
    pluck("mean")
  if (curr_rmse < mlp_sfd_sa_rmse) {
    mlp_sfd_sa_rmse <- curr_rmse
    mlp_sfd_sa_best <- c(mlp_sfd_sa_best, i)
  }
}

iters_sfd_sa <- 
  mlp_sfd_sa %>% 
  collect_extracts() %>% 
  unnest(.extracts) %>% 
  rename(num_epochs = .extracts)

load(file.path(tempdir(), "sa_history.RData"))

# ------------------------------------------------------------------------------

save_obj <- ls(pattern = ("(^iter)|(met$)|(ci$)|(best$)|(time$)|(history)|(_param$)"))
save(list = save_obj, file = "~/github/website/RData/barley_iterative.RData")

# ------------------------------------------------------------------------------
# Session versions

sessioninfo::session_info()

if ( !interactive() ) {
  q("no")
}
