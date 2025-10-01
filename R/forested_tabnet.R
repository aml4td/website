torch::torch_set_num_threads(10)
torch::torch_set_num_interop_threads(10)

# ------------------------------------------------------------------------------

library(tidymodels)
library(tabnet)
library(spatialsample)

# ------------------------------------------------------------------------------

load("~/content/website/RData/forested_data.RData")

base_rec <-
	recipe(class ~ ., data = forested_train) |>
	step_range(all_numeric_predictors(), min = -1)

tbn_model <- tabnet(
	num_steps = tune(),
	penalty = tune(),
	batch_size = tune(), 
	epochs = 50,
	learn_rate = tune(),
	rate_decay = "reduce_on_plateau",
	momentum = tune(),
	num_independent = tune(),
	feature_reusage = tune(), 
	decision_width = tune(),
	attention_width = tune(),
	early_stopping_monitor = "valid_loss",
	skip_importance = TRUE,
	verbose = FALSE
) %>%
	set_mode("classification") %>%
	set_engine("torch")

tnb_wflow <- workflow(base_rec, tbn_model)

tnb_param <- 
	tnb_wflow |> 
	extract_parameter_set_dials() |> 
	update(
		momentum = momentum(c(0.01, 0.40)),
		batch_size = batch_size(c(8L, 11L))
	)

tbn_time <- 
	system.time({
		
		set.seed(282)
		tbn_res <- 
			tnb_wflow |> 
			tune_grid(
				resamples = forested_rs,
				param_info = tnb_param, 
				grid = 50, 
				control = control_resamples(save_pred = TRUE)
			)
		
	})

tbn_mtr <- collect_metrics(tbn_res)
tbn_best <- select_best(tbn_res, metric = "brier_class")
tbn_pred <- collect_predictions(tbn_res, parameters = tbn_best)
tbn_time <- tbn_time[3]
	
# ------------------------------------------------------------------------------

save(tbn_mtr, tbn_best, tbn_pred, tbn_time, tbn_res, 
		 file = "RData/forested_tabnet.RData")
