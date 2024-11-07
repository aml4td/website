suppressPackageStartupMessages(library(tidymodels))
suppressPackageStartupMessages(library(finetune))
suppressPackageStartupMessages(library(future))
suppressPackageStartupMessages(library(bestNormalize))
suppressPackageStartupMessages(library(GA))
suppressPackageStartupMessages(library(glue))

# pak::pak(c("tidymodels/tune@clear-gp"), ask = FALSE)

source("~/content/website/R/setup_chemometrics.R")

stub <- "~/content/website/RData/two_param_iter"
plan("multisession")

# ------------------------------------------------------------------------------

resolve_sa_path <- function(x, iter) {
  x2 <- x %>% filter(.iter <= iter)
  restarts <- grep("restart", x2$results[x2$.iter < iter])
  bests <- grep("new best", x2$results)
  
  # delete restarted chunks
  rm <- NULL
  for (i in restarts) {
    recent_best <- max(bests[bests <= i])
    rm <- c(rm, (recent_best + 1):i)
  }
  rm <- sort(unique(rm))
  if ( length(rm) > 0 ) {
    x2 <- x2[-rm,]
  }
  # remove previously discarded
  
  discarded <- which(x2$.iter < iter & x2$results == "discard suboptimal")
  if ( length(discarded) > 0 ) {
    x2 <- x2[-discarded,]
  }
  x2 %>% rename(RMSE = mean)
}

describe_sa_result <- function(x) {
  require(cli)
  mtr_current <- x$RMSE[nrow(x)]
  chr_current <- format(mtr_current, digits = 3, scientific = FALSE)
  
  good_verbs <- c("improvement over the last RMSE of", "decrease from the previous value of")
  bad_verbs <- c("degradation from the previous RMSE of", "worse value than the last RMSE of")
  
  if (nrow(x) > 1) {
    mtr_prev <- x$RMSE[nrow(x) - 1]
    chr_prev <- format(mtr_prev, digits = 3, scientific = FALSE)
    
    pct_diff <- (mtr_prev - mtr_current) / mtr_prev * 100
    pct_diff <- round(pct_diff, 1)  
    if (pct_diff > 0) {
      res <- sample(good_verbs, 1)
    } else {
      res <- sample(bad_verbs, 1)
    }
    txt <- format_inline("The current RMSE is {chr_current}, which is a {abs(pct_diff)}% {res} {chr_prev}.")
  } else {
    txt <- format_inline("The current RMSE is {chr_current}.")
  }
  txt
}

reproduce_gp_surface <- function(file) {
  require(GPfit)
  # The objects here show the GP fit with the current set of resampled values.
  # We will predict what the _next_ candidate should be so we will have to
  # use different columns for the iteration.
  load(file)
  
  # cli::cli_inform("For iteration {i}, the GP had results for {nrow(x$X)} candidates.")
  
  pred <- predict(x, large_scaled_grid)
  grid_predictions <-
    large_grid %>%
    dplyr::mutate(.mean = pred$Y_hat, .sd = sqrt(pred$MSE))
  obj <-
    predict(exp_improve(),
            grid_predictions,
            maximize = FALSE, # since we are minimizing RMSE
            best = score_card$best_val)
  
  # make a normalized objective function for visualizations
  rngs <- range(obj$objective)
  obj$objective_scaled <- (obj$objective - rngs[1]) / (rngs[2] - rngs[1])
  ret <- bind_cols(grid_predictions, obj)
  
  ret$iter <- i
  ret$.iter <- i
  ret$num_points <- nrow(x$X)
  ret
}

yardstick_fitness <- function(values, wflow, param_info, metrics, ...) {
  
  require(tidymodels)
  # load req packages
  info <- as_tibble(metrics)
  
  values <- purrr::map2_dbl(values, param_info$object, ~ dials::value_inverse(.y, .x))
  values <- matrix(values, nrow = 1)
  colnames(values) <- param_info$id
  values <- as_tibble(values)
  ctrl <- control_grid(allow_par = FALSE)
  
  res <- tune_grid(
    wflow,
    metrics = metrics,
    param_info = param_info,
    grid = values,
    control = ctrl,
    ...
  )
  best_res <- show_best(res, metric = info$metric[1])
  if (info$direction == "minimize") {
    obj_value <- -best_res$mean
  } else {
    obj_value <- best_res$mean
  }
  obj_value
}

save_details <- function(object, ...) {
  pop <- object@population
  colnames(pop) <- c("cost", "scale_factor")
  pop <- tibble::as_tibble(pop)
  pop$fitness <- -object@fitness
  pop$time <- lubridate::now()
  
  if(!exists("ga_generations", envir = globalenv())) {
    assign("ga_generations", list(pop), envir = globalenv())
  } else {
    ga_res <- get("ga_generations", envir = globalenv())
    assign("ga_generations", append(ga_generations, list(pop)), envir = globalenv()) 
  }
  object 
}

# ------------------------------------------------------------------------------

rec <-
  recipe(barley ~ ., data = barley_train) %>%
  step_orderNorm(all_predictors()) %>% 
  step_pca(all_predictors(), num_comp = 10) %>%
  step_normalize(all_predictors())

svm_spec <-
  svm_poly(cost = tune(), degree = 4, scale_factor = tune()) %>%
  set_mode("regression")

svm_wflow <- workflow(rec, svm_spec)

svm_param <-
  svm_wflow %>%
  extract_parameter_set_dials() %>%
  update(
    cost = cost(c(-10, 10)),
    scale_factor = scale_factor(c(-10, -1/10))
  )

reg_mtr <- metric_set(rmse)

# ------------------------------------------------------------------------------

init_grid <- grid_space_filling(svm_param, size = 3)

# used for bo plots:
large_grid <- grid_regular(svm_param, levels = 50)
large_scaled_grid <- encode_set(large_grid, svm_param, as_matrix = TRUE)

# ------------------------------------------------------------------------------
cli::cli_rule("intial SFD")

initial_time <- system.time({
  set.seed(21)
  initial_res <-
    svm_wflow %>%
    tune_grid(
      resamples = barley_rs,
      grid = init_grid,
      metrics = reg_mtr,
      control = control_grid(save_pred = TRUE)
    )
})

initial_mtr <- collect_metrics(initial_res)

show_best(initial_res, metric = "rmse")

save(initial_mtr, initial_time, file = glue("{stub}_initial.RData"))

# ------------------------------------------------------------------------------

# For visualization

# set.seed(531)
# svm_large_res <-
#   svm_wflow %>%
#   tune_grid(
#     resamples = barley_rs,
#     grid = grid_regular(svm_param, levels = 20),
#     metrics = reg_mtr,
#     control = control_grid(parallel_over = "everything")
#   )

# ------------------------------------------------------------------------------
cli::cli_rule("Bayesian optimization")

bo_time <- system.time({
  set.seed(102)
  bo_res <-
    svm_wflow %>%
    tune_bayes(
      resamples = barley_rs,
      initial = initial_res,
      iter = 51,
      param_info = svm_param,
      metrics = reg_mtr,
      control = control_bayes(
        no_improve = Inf,
        verbose_iter = TRUE,
        verbose = FALSE,
        save_gp_scoring = TRUE,
        save_pred = TRUE,
      )
    )
})


###

bo_ci <-
  int_pctl(bo_res, times = 2000, metrics = reg_mtr, alpha = 0.1) %>%
  select(-.metric, -.config)
bo_mtr <- collect_metrics(bo_res)
bo_gp_files <- list.files(tempdir(), pattern = "gp", full.names = TRUE)
bo_tile <- map_dfr(bo_gp_files, reproduce_gp_surface)

###

old_bo_points <- new_bo_points <- NULL
for (i in 1:max(bo_tile$iter)) {
  prev_iter_points <-
    bo_mtr %>%
    filter(.iter < i & .iter != 0) %>%
    mutate(iter = i)
  old_bo_points <- bind_rows(old_bo_points, prev_iter_points)
  curr_iter_points <-
    bo_mtr %>%
    filter(.iter == i) %>%
    mutate(iter = i)
  new_bo_points <- bind_rows(new_bo_points, curr_iter_points)
}

save(bo_mtr, bo_ci, bo_tile, bo_time, init_grid, old_bo_points, new_bo_points,
     file = glue("{stub}_bo.RData"))

# ------------------------------------------------------------------------------
cli::cli_rule("Simulated annealing")

sa_time <- system.time({
  set.seed(381)
  sa_res <-
    svm_wflow %>%
    tune_sim_anneal(
      resamples = barley_rs,
      initial = initial_res,
      iter = 50,
      param_info = svm_param,
      metrics = reg_mtr,
      control = control_sim_anneal(
        no_improve = Inf,
        verbose_iter = TRUE,
        verbose = FALSE,
        save_history = TRUE,
        save_pred = TRUE
      )
    )
})

sa_ci <-
  int_pctl(sa_res, times = 2000, metrics = reg_mtr, alpha = 0.1) %>%
  select(-.metric, -.config)
sa_mtr <- collect_metrics(sa_res)
load(file.path(tempdir(), "sa_history.RData"))
sa_history <- result_history

# ------------------------------------------------------------------------------
# Items to save for the shiny app

sa_init <-
  sa_history %>%
  filter(.iter == 0) %>%
  rename(RMSE = mean)
best_init <-
  sa_init %>%
  slice_min(RMSE) %>%
  select(.iter, cost, scale_factor)
poor_init <-
  anti_join(sa_init, best_init, by = c(".iter", "cost", "scale_factor")) %>%
  select(.iter, cost, scale_factor)

# loop over path and descriptions

paths <- iter_best <- iter_label <- iter_descr <- vector(mode = "list", length = 50)

for (i in 1:50) {
  current_path <-
    resolve_sa_path(sa_history, i) %>%
    anti_join(poor_init, by = c(".iter", "cost", "scale_factor"))
  paths[[i]] <- current_path

  last_best <-
    sa_history %>%
    filter(results == "new best" & .iter < i) %>%
    slice_max(.iter)
  iter_best[[i]] <- last_best


  iter_descr[[i]] <- describe_sa_result(current_path)

  last_best_iter <-
    last_best %>%
    pluck(".iter")

  res <- unique(sa_history$results[sa_history$.iter == i])
  if (res == "restart from best") {
    res <- paste(res, "at iteration", last_best_iter)
  }

  iter_label[[i]] <- paste0("iteration ", i, ": ", res)
}

save(sa_mtr, sa_ci, sa_history, sa_time, init_grid, paths, iter_best, iter_label,
     iter_descr, file = glue("{stub}_sa.RData"))

# ------------------------------------------------------------------------------
cli::cli_rule("Genetic algorithm")

min_vals <- map_dbl(svm_param$object, ~ .x$range[[1]])
max_vals <- map_dbl(svm_param$object, ~ .x$range[[2]])

pop_size <- 50
grid_ga <- grid_space_filling(svm_param, size = pop_size, original = FALSE)
grid_ga$cost <- log2(grid_ga$cost)
grid_ga$scale_factor <- log10(grid_ga$scale_factor)

ga_time <- system.time({
  set.seed(1528)
  ga_res <-
    ga(
      type = "real-valued",
      fitness = yardstick_fitness,
      lower = min_vals,
      upper = max_vals,
      popSize = pop_size,
      suggestions = as.matrix(grid_ga),
      maxiter = 10,
      keepBest = TRUE,
      seed = 39,
      wflow = svm_wflow,
      param_info = svm_param,
      metrics = reg_mtr,
      resamples = barley_rs,
      postFitness = save_details,
      parallel = "multicore"
    )
})

ga_history <- 
  map2_dfr(seq_along(ga_generations), ga_generations, ~ mutate(.y, generation = .x) %>% distinct()) %>% 
  mutate(cost = 2^cost, scale_factor = 10^scale_factor)

save(ga_history, ga_time, ga_res, file = glue("{stub}_ga.RData"))

# ------------------------------------------------------------------------------
cli::cli_rule("Reproducability")

sessioninfo::session_info()

if (!interactive()) {
  q("no")
}
