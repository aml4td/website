
fn <- function(x, y) {
	(x * cos(.5 * x)) - (2 * exp(-6 * (y - 0.3)^2)) + 0.2 * (x * y)
}

fn_p <- function(prm) {
	fn(prm[1], prm[2])
}

deriv_form <-
	deriv(
		quote((x * cos(.5 * x)) - (2 * exp(-6 * (y - 0.3)^2)) + 0.2 * (x * y)),
		c("x", "y")
	)


deriv_1 <- function(param) {
	x <- param[1]
	y <- param[2]
	.expr1 <- 0.5 * x
	.expr2 <- cos(.expr1)
	.expr5 <- y - 0.3
	.expr8 <- exp(-6 * .expr5^2)
	.value <- x * .expr2 - 2 * .expr8 + 0.2 * (x * y)
	.grad <- rep(NA, 2)
	.grad[1] <- .expr2 - x * (sin(.expr1) * 0.5) + 0.2 * y
	.grad[2] <- 2 * (.expr8 * (6 * (2 * .expr5))) + 0.2 * x
	.grad
}

deriv_x <- function(x, y) {
	deriv_1(c(x, y))[1]
}

deriv_y <- function(x, y) {
	deriv_1(c(x, y))[2]
}

# ------------------------------------------------------------------------------

x_seq <- seq(0, 10, length.out = 200)
y_seq <- seq(-1, 1, length.out = 200)

loss_grid <-
	crossing(
		x = x_seq,
		y = y_seq
	) |>
	mutate(
		res = map2_dbl(x, y, fn),
		d_x =  map2_dbl(x, y, deriv_x),
		d_y =  map2_dbl(x, y, deriv_y)
	)

long_grid <- 
	loss_grid |> 
	pivot_longer(
		cols = c(res, d_x, d_y),
		names_to = "type",
		values_to = "value"
	)

z_mat <- outer(x_seq, y_seq, fn)

grid_bst <- 
	loss_grid |> 
	slice_min(res) |> 
	mutate(type = "minimum") |> 
	select(x, y, type)


stationary <- 
	loss_grid |> 
	filter((abs(d_x) < 0.05 & abs(d_y) < 0.05 )) |> 
	mutate(
		res_approx = round(res, 1),
		type = ifelse(res > 0.9, "maximum", "saddle point")
	) |> 
	slice_head(n = 1, by = res_approx) |> 
	select(x, y, type) |> 
	bind_rows(grid_bst)

# ------------------------------------------------------------------------------

base_sgd_plot <- function(dat, title = "SGD") {
	dat |>
		ggplot(aes(x, y)) +
		geom_tile(data = loss_grid, aes(fill = res), show.legend = FALSE) +
		geom_contour(
			data = loss_grid,
			aes(z = res),
			bins = 10,
			alpha = 1 / 4,
			col = "grey50"
		) +
		geom_path(
			aes(col = start),
			linewidth = 3 /4,
			alpha = 3 / 4,
			show.legend = FALSE
		) +
		
		geom_point(data = grid_bst, cex = 2, pch = 1, col = "grey50") +
		scale_fill_gradient(low = "white", high = "grey50") +
		scale_color_brewer(palette = "Dark2") +
		coord_fixed(ratio = 5) +
		labs(
			title = title,
			x = expression(theta[1]),
			y = expression(theta[2])
		) +
		theme(panel.grid = element_blank())
}

# ------------------------------------------------------------------------------

is_conv <- function(loss, i, tol = 0.001) {
  dif <- (abs(loss[i + 1] - loss[i]) / abs(loss[i]))
  dif <= tol
}

basic <- function(prm, iter = 500, rate = 0.1, sched = "constant", ...) {
	.prm <- matrix(NA_real_, ncol = 2, nrow = iter + 1)
	.prm[1, ] <- prm
	
	.loss <- rep(NA_real_, iter + 1)
	.loss[1] <- fn_p(prm)
	grd <- deriv_1(prm)
	
	.rate <- rate
	for (i in 1:iter) {
		if (prm[1] < 0 | prm[1] > 10 | prm[2] > 1 | prm[2] < -1) {
			break()
		}
		
		if (sched == "step") {
			.rate <- brulee::schedule_step(i, ...)
		} else if (sched == "cyclic") {
			.rate <- brulee::schedule_cyclic(i, ...)
		} else if (sched == "decay") {
			.rate <- brulee::schedule_decay_time(i, ...)
		}
		
		prm <- prm - .rate * grd
		.prm[i + 1, ] <- prm
		.loss[i + 1] <- fn_p(prm)
		grd <- deriv_1(prm)
		if (is_conv(.loss, i, 1e-6)) {
		  break()
		}
	}
	
	prm_df <- cbind(.prm, .loss)
	colnames(prm_df) <- c("x", "y", "loss")
	prm_df |>
		as_tibble() |>
		drop_na() %>%
		mutate(schedule = sched, epoch = row_number() - 1)
}

adagrad <- function(prm, iter = 500, rate = 0.1, sched = "constant", ...) {
	eps <- 0.0001
	
	.prm <- matrix(NA_real_, ncol = 2, nrow = iter + 1)
	.prm[1, ] <- prm
	
	.loss <- rep(NA_real_, iter + 1)
	.loss[1] <- fn_p(prm)
	grd <- deriv_1(prm)
	grd_run <- rep(0, 2)
	
	.rate <- rate
	for (i in 1:iter) {
		if (prm[1] < 0 | prm[1] > 10 | prm[2] > 1 | prm[2] < -1) {
			break()
		}
		
		if (sched == "step") {
			.rate <- brulee::schedule_step(i, ...)
		} else if (sched == "cyclic") {
			.rate <- brulee::schedule_cyclic(i, ...)
		} else if (sched == "decay") {
			.rate <- brulee::schedule_decay_time(i, ...)
		}
		
		grd_run <- grd_run + grd^2
		.update <- grd / (eps + sqrt(grd_run))
		prm <- prm - .rate * .update
		.prm[i + 1, ] <- prm
		.loss[i + 1] <- fn_p(prm)
		if (is_conv(.loss, i, 1e-6)) {
		  break()
		}
	}
	
	prm_df <- .prm
	colnames(prm_df) <- c("x", "y")
	prm_df |> as_tibble() |> drop_na() %>% mutate(schedule = sched)
}

adadelta <- function(
		prm,
		iter = 500,
		rate = 0.1,
		grd_decay = 0.9,
		sched = "constant",
		...
) {
	eps <- 0.0001
	
	.prm <- matrix(NA_real_, ncol = 2, nrow = iter + 1)
	.prm[1, ] <- prm
	
	.loss <- rep(NA_real_, iter + 1)
	.loss[1] <- fn_p(prm)
	grd <- deriv_1(prm)
	grd_run <- accum_run <- rep(0, 2)
	
	.rate <- rate
	for (i in 1:iter) {
		if (prm[1] < 0 | prm[1] > 10 | prm[2] > 1 | prm[2] < -1) {
			break()
		}
		
		if (sched == "step") {
			.rate <- brulee::schedule_step(i, ...)
		} else if (sched == "cyclic") {
			.rate <- brulee::schedule_cyclic(i, ...)
		} else if (sched == "decay") {
			.rate <- brulee::schedule_decay_time(i, ...)
		}
		
		grd_run <- grd_decay * grd_run + (1 - grd_decay) * (grd^2)
		.update <- (sqrt(accum_run + eps) / sqrt(grd_run + eps)) * grd
		
		prm <- prm - .rate * .update
		.prm[i + 1, ] <- prm
		.loss[i + 1] <- fn_p(prm)
		
		if (is_conv(.loss, i, 1e-6)) {
		  break()
		}
		
		accum_run = grd_decay * accum_run + (1 - grd_decay) * (.update^2)
		
		grd <- deriv_1(prm)
		
		
	}
	
	prm_df <- .prm
	colnames(prm_df) <- c("x", "y")
	prm_df |> as_tibble() |> drop_na() %>% mutate(schedule = sched)
}

nesterov <- function(
		prm,
		iter = 500,
		momentum = 0,
		rate = 0.1,
		sched = "constant",
		...
) {
	.prm <- matrix(NA_real_, ncol = 2, nrow = iter + 1)
	.prm[1, ] <- prm
	
	.loss <- rep(NA_real_, iter + 1)
	.loss[1] <- fn_p(prm)
	grd <- deriv_1(prm)
	
	vel <- grd * 0
	
	.rate <- rate
	for (i in 1:iter) {
		if (prm[1] < 0 | prm[1] > 10 | prm[2] > 1 | prm[2] < -1) {
			break()
		}
		
		if (sched == "step") {
			.rate <- brulee::schedule_step(i, ...)
		} else if (sched == "cyclic") {
			.rate <- brulee::schedule_cyclic(i, ...)
		} else if (sched == "decay") {
			.rate <- brulee::schedule_decay_time(i, ...)
		}
		
		vel <- momentum * vel - .rate * deriv_1(prm + momentum * vel)
		
		prm <- prm + vel
		.prm[i + 1, ] <- prm
		.loss[i + 1] <- fn_p(prm)
	}
	
	prm_df <- .prm
	colnames(prm_df) <- c("x", "y")
	prm_df |> as_tibble() |> drop_na() %>% mutate(schedule = sched)
}


adam <- function(
    prm,
    iter = 1000,
    momentum_decay = 0.9,
    velocity_decay = 0.9,
    rate = 0.1,
    sched = "constant",
    ...
) {
  
  eps <-1e-08
  .prm <- matrix(NA_real_, ncol = 2, nrow = iter + 1)
  .prm[1, ] <- prm
  
  .loss <- rep(NA_real_, iter + 1)
  .loss[1] <- fn_p(prm)
  grd <- deriv_1(prm)
  
  vel <- mo <- grd * 0
  
  .rate <- rate
  for (i in 1:iter) {
    if (prm[1] < 0 | prm[1] > 10 | prm[2] > 1 | prm[2] < -1) {
      break()
    }
    
    if (sched == "step") {
      .rate <- brulee::schedule_step(i, ...)
    } else if (sched == "cyclic") {
      .rate <- brulee::schedule_cyclic(i, ...)
    } else if (sched == "decay") {
      .rate <- brulee::schedule_decay_time(i, ...)
    }
    
    grad <- deriv_1(prm)
    
    mo <- momentum_decay * mo + (1 - momentum_decay) * grad
    vel <- velocity_decay * vel + (1 - velocity_decay) * grad^2
    
    mo_est <- mo / (1 - momentum_decay^(i + 1))
    vel_est <- vel / (1 - velocity_decay^(i + 1))
    
    prm <- prm - .rate / (sqrt(vel_est) + eps) * mo_est
    .prm[i + 1, ] <- prm
    .loss[i + 1] <- fn_p(prm)
  }
  
  prm_df <- .prm
  colnames(prm_df) <- c("x", "y")
  prm_df |> as_tibble() |> drop_na() %>% mutate(schedule = sched)
}

momentum <- function(
    prm,
    iter = 50,
    momentum = 0.9,
    rate = 0.1,
    sched = "constant",
    ...
) {
  
  eps <-1e-08
  .prm <- matrix(NA_real_, ncol = 2, nrow = iter + 1)
  .prm[1, ] <- prm
  
  .loss <- rep(NA_real_, iter + 1)
  .loss[1] <- fn_p(prm)
  grd <- deriv_1(prm)
  
  vel <- grd * 0
  
  .rate <- rate
  for (i in 1:iter) {
    if (prm[1] < 0 | prm[1] > 10 | prm[2] > 1 | prm[2] < -1) {
      break()
    }
    
    if (sched == "step") {
      .rate <- brulee::schedule_step(i, ...)
    } else if (sched == "cyclic") {
      .rate <- brulee::schedule_cyclic(i, ...)
    } else if (sched == "decay") {
      .rate <- brulee::schedule_decay_time(i, ...)
    }
    
    grad <- deriv_1(prm)
    vel <- momentum * vel - .rate * grad
    
    prm <- prm + vel
    .prm[i + 1, ] <- prm
    .loss[i + 1] <- fn_p(prm)
  }
  
  prm_df <- .prm
  colnames(prm_df) <- c("x", "y")
  prm_df |> as_tibble() |> drop_na() %>% mutate(schedule = sched)
}

adagrad <- function(
    prm,
    iter = 1000,
    rate = 0.1,
    sched = "constant",
    ...
) {
  
  eps <-1e-08
  .prm <- matrix(NA_real_, ncol = 2, nrow = iter + 1)
  .prm[1, ] <- prm
  
  .loss <- rep(NA_real_, iter + 1)
  .loss[1] <- fn_p(prm)
  grd <- deriv_1(prm)
  
  running <- grd * 0
  
  .rate <- rate
  for (i in 1:iter) {
    if (prm[1] < 0 | prm[1] > 10 | prm[2] > 1 | prm[2] < -1) {
      break()
    }
    
    if (sched == "step") {
      .rate <- brulee::schedule_step(i, ...)
    } else if (sched == "constant") {
      .rate <- brulee::schedule_cyclic(i, ...)
    } else if (sched == "decay") {
      .rate <- brulee::schedule_decay_time(i, ...)
    }
    
    grad <- deriv_1(prm)
    running <- running + grad^2
    
    # print(signif(running, 3))
    
    prm <- prm - .rate / (sqrt(running + eps)) * grad
    .prm[i + 1, ] <- prm
    .loss[i + 1] <- fn_p(prm)
    if (is_conv(.loss, i, 1e-6)) {
      break()
    }
  }
  
  prm_df <- .prm
  colnames(prm_df) <- c("x", "y")
  prm_df |> as_tibble() |> drop_na() %>% mutate(schedule = sched)
}

rms_prop_nesterov <- function(
    prm,
    iter = 100,
    momentum = 0.9,
    decay = 0.9,
    rate = 0.1,
    sched = "constant",
    ...
) {
  
  eps <-1e-0
  .prm <- matrix(NA_real_, ncol = 2, nrow = iter + 1)
  .prm[1, ] <- prm
  
  .loss <- rep(NA_real_, iter + 1)
  .loss[1] <- fn_p(prm)
  
  running <- delta <- prm * 0
  
  .rate <- rate
  for (i in 1:iter) {
    if (prm[1] < 0 | prm[1] > 10 | prm[2] > 1 | prm[2] < -1) {
      break()
    }
    
    if (sched == "step") {
      .rate <- brulee::schedule_step(i, ...)
    } else if (sched == "constant") {
      .rate <- brulee::schedule_cyclic(i, ...)
    } else if (sched == "decay") {
      .rate <- brulee::schedule_decay_time(i, ...)
    }
    
    prm_step <- prm - momentum * delta
    grad <- deriv_1(prm_step)
    running <- decay * running + (1 - decay) * grad^2
    prm <- prm + (momentum * delta) - (rate / sqrt(running + eps) * grad)
    .prm[i + 1, ] <- prm
    .loss[i + 1] <- fn_p(prm)
    if (is_conv(.loss, i, 1e-6)) {
      break()
    }
  }
  
  prm_df <- .prm
  colnames(prm_df) <- c("x", "y")
  prm_df |> as_tibble() |> drop_na() %>% mutate(schedule = sched)
}

# ------------------------------------------------------------------------------

point_saddle <- c(2,  0.25)
point_corner <- c( 10, 1)

# ------------------------------------------------------------------------------
# Learning rate scheduler examples

rates_saddle_constant <-
	basic(
		point_saddle,
		sched = "constant",
		initial = 0.1,
		reduction = 0.5,
		steps = 20
	) |>
	mutate(start = "mid", rate = 0.1)

rates_corner_constant <-
	basic(
		point_corner,
		sched = "constant",
		initial = 0.1,
		reduction = 0.5,
		steps = 20
	) |>
	mutate(start = "corner", rate = 0.1)

rates_saddle_step <-
	basic(
		point_saddle,
		sched = "step",
		initial = 0.1,
		reduction = 0.5,
		steps = 20
	) |>
	mutate(start = "mid", rate = 0.1)

rates_corner_step <-
	basic(
		point_corner,
		sched = "step",
		initial = 0.1,
		reduction = 0.5,
		steps = 20
	) |>
	mutate(start = "corner", rate = 0.1)


rates_saddle_cyclic <-
	basic(
		point_saddle,
		sched = "cyclic",
		initial = 0.001,
		largest = 0.1,
		step_size = 10
	) |>
	mutate(start = "mid", rate = 0.001)

rates_corner_cyclic <-
	basic(
		point_corner,
		sched = "cyclic",
		initial = 0.001,
		largest = 0.1,
		step_size = 10
	) |>
	mutate(start = "corner")


rates_saddle_decay <-
	basic(
		point_saddle,
		sched = "decay",
		decay = 0.025
	) |>
	mutate(start = "mid")

rates_corner_decay <-
	basic(
		point_corner,
		sched = "decay",
		decay = 0.025
	) |>
	mutate(start = "corner")

rates <-
	bind_rows(
		rates_corner_constant,
		rates_corner_cyclic,
		rates_corner_step,
		rates_corner_decay,
		rates_saddle_constant,
		rates_saddle_cyclic,
		rates_saddle_step,
		rates_saddle_decay
	)

# ------------------------------------------------------------------------------

adam_saddle_cyclic <-
  adam(
    point_saddle,
    sched = "cyclic",
    initial = 0.001,
    largest = 0.1,
    step_size = 10
  ) |>
  mutate(start = "mid")

adam_corner_cyclic <-
  adam(
    point_corner,
    sched = "cyclic",
    initial = 0.001,
    largest = 0.1,
    step_size = 10
  ) |>
  mutate(start = "corner")

adam_res <-
  bind_rows(
    adam_saddle_cyclic,
    adam_corner_cyclic
  ) |> 
  mutate(technique = "ADAM")

momentum_saddle_cyclic <-
  momentum(
    point_saddle,
    sched = "cyclic",
    initial = 0.001,
    largest = 0.1,
    step_size = 10,
    momentum = 2/3
  ) |>
  mutate(start = "mid")

momentum_corner_cyclic <-
  momentum(
    point_corner,
    sched = "cyclic",
    initial = 0.001,
    largest = 0.1,
    step_size = 10,
    momentum = 2/3
  ) |>
  mutate(start = "corner")

momentum_res <-
  bind_rows(
    momentum_saddle_cyclic,
    momentum_corner_cyclic
  ) |> 
  mutate(technique = "Momentum")


adagrad_saddle_constant <-
  adagrad(point_saddle) |>
  mutate(start = "mid")

adagrad_corner_constant <-
  adagrad(point_corner) |>
  mutate(start = "corner")

adagrad_res <-
  bind_rows(
    adagrad_saddle_constant,
    adagrad_corner_constant
  ) |> 
  mutate(technique = "AdaGrad")

rms_prop_saddle_constant <-
  rms_prop_nesterov(
    point_saddle,
    sched = "constant"
  ) |>
  mutate(start = "mid", rate = 0.001)

rms_prop_corner_constant <-
  rms_prop_nesterov(
    point_corner,
    sched = "constant"
  ) |>
  mutate(start = "corner")

rms_prop_res <-
  bind_rows(
    rms_prop_saddle_constant,
    rms_prop_corner_constant
  ) |> 
  mutate(technique = "RMSprop + Nesterov")

