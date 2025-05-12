# Requires the sources in shiny-setup.R

data(fossil)

ui <- page_fillable(
#	theme = grid_theme,
	padding = "1rem",
	layout_columns(
		fill = FALSE,
		col_widths = breakpoints(sm = c(-3, 6, -3)),
		sliderInput(
			"global_deg",
			label = "Polynomial Degree",
			min = 1L,
			max = 20L,
			step = 1L,
			value = 3L,
			ticks = TRUE
		) # sliderInput
	), # layout_columns
	layout_columns(
		fill = FALSE,
		col_widths = breakpoints(sm = c(-1, 10, -1)),
		as_fill_carrier(plotOutput('global'))
	)
)

server <- function(input, output, session) {
	maybe_lm <- function(x) {
		try(lm(y ~ poly(x, input$piecewise_deg), data = x), silent = TRUE)
	}

	names_zero_padded <- function(num, prefix = "x", call = rlang::caller_env()) {
	  rlang:::check_number_whole(num, min = 1, call = call)
	  ind <- format(seq_len(num))
	  ind <- gsub(" ", "0", ind)
	  paste0(prefix, ind)
	}
	
	expansion_to_tibble <- function(x, original, prefix = "term ") {
		cls <- class(x)[1]
		nms <- names_zero_padded(ncol(x), prefix)
		colnames(x) <- nms
		x <- as_tibble(x)
		x$variable <- original
		res <- tidyr::pivot_longer(x, cols = c(-variable))
		if (cls != "poly") {
			res <- res[res$value > .Machine$double.eps, ]
		}
		res
	}

	mult_poly <- function(dat, degree = 4) {
		rng <- extendrange(dat$x, f = .025)
		grid <- seq(rng[1], rng[2], length.out = 1000)
		grid_df <- tibble(x = grid)
		feat <- poly(grid_df$x, degree)
		res <- expansion_to_tibble(feat, grid_df$x)

		# make some random names so that we can plot the features with distinct colors
		rand_names <- lapply(
			1:degree,
			function(x) paste0(sample(letters)[1:10], collapse = "")
		)
		rand_names <- unlist(rand_names)
		rand_names <- tibble(name = unique(res$name), name2 = rand_names)
		res <- dplyr::inner_join(res, rand_names, by = dplyr::join_by(name)) %>%
			dplyr::select(-name) %>%
			dplyr::rename(name = name2)
		res
	}

	col_rect <- ggplot2::element_rect(fill = "#fcfefe", colour = "#fcfefe")
	theme_light_bl <- function() {
		ggplot2::theme(
			panel.background = col_rect,
			panel.grid.major = col_rect,
			panel.grid.minor = col_rect,
			panel.border = col_rect,
			legend.background = col_rect,
			legend.key = col_rect,
			plot.background = col_rect
		)
	}
	
	# ------------------------------------------------------------------------------

	spline_example <- tibble(x = fossil$age, y = fossil$strontium.ratio)
	rng <- extendrange(fossil$age, f = .025)
	grid <- seq(rng[1], rng[2], length.out = 1000)
	grid_df <- tibble(x = grid)
	alphas <- 1 / 4
	line_wd <- 1.0

	base_p <- spline_example %>%
		ggplot(aes(x = x, y = y)) +
		geom_point(alpha = 3 / 4, pch = 1, cex = 3) +
		labs(x = "Age", y = "Isotope Ratio") +
		lims(x = rng) +
		theme_light_bl()

	output$global <- renderPlot({
		poly_fit <- lm(y ~ poly(x, input$global_deg), data = spline_example)
		poly_pred <- predict(
			poly_fit,
			grid_df,
			interval = "confidence",
			level = .90
		) %>%
			bind_cols(grid_df)

		global_p <- base_p

		if (input$global_deg > 0) {
			global_p <- global_p +
				geom_ribbon(
					data = poly_pred,
					aes(y = NULL, ymin = lwr, ymax = upr),
					alpha = 1 / 15
				) +
				geom_line(
					data = poly_pred,
					aes(y = fit),
					col = "black",
					linewidth = line_wd
				) +
				theme(
					plot.margin = margin(t = -20, r = 0, b = 0, l = 0),
					panel.background = col_rect,
					plot.background = col_rect,
					legend.background = col_rect,
					legend.key = col_rect
				)

			feature_p <- poly(grid_df$x, input$global_deg) %>%
				expansion_to_tibble(grid_df$x) %>%
				ggplot(aes(variable, y = value, group = name, col = name)) +
				geom_line(show.legend = FALSE) + # , linewidth = 1, alpha = 1 / 2
				theme_void() +
				theme(
					plot.margin = margin(t = 0, r = 0, b = -20, l = 0),
					panel.background = col_rect,
					plot.background = col_rect,
					legend.background = col_rect,
					legend.key = col_rect
				) +
				scale_color_viridis(discrete = TRUE, option = "turbo")

			p <- (feature_p / global_p) + plot_layout(heights = c(1.5, 4))
		}

		print(p)
	})
}

app <- shinyApp(ui, server)
