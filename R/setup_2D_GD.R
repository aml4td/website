
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
			alpha = 1 / 2,
			col = "grey50"
		) +
		geom_path(
			aes(col = start),
			linewidth = 1,
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
		grd <- deriv_1(prm)
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
		
		delt <- (.loss[i + 1] - .loss[i]) / .loss[i]
		if (abs(delt) < .Machine$double.eps^0.5) {
			cli::cli_inform("Stopped at epoch {i+1}")
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

