data(fossil)

ui <- page_fillable(
	theme = grid_theme,
	padding = "1rem",
	layout_columns(
		fill = FALSE,
		col_widths = breakpoints(sm = c(-1, 5, 5, -1)),
		sliderInput(
			"piecewise_deg",
			label = "Polynomial Degree",
			min = 0L,
			max = 6L,
			step = 1L,
			value = 4L
		), # sliderInput
		sliderInput(
			"cuts",
			label = "Cutpoints",
			min = 93L,
			max = 122L,
			step = 1,
			value = c(101, 118)
		) # sliderInput
	), # layout_columns
	layout_columns(
		fill = FALSE,
		col_widths = breakpoints(sm = c(-1, 10, -1)),
		as_fill_carrier(plotOutput('pieces'))
	)
)

server <- function(input, output, session) {
	maybe_lm <- function(x) {
		try(lm(y ~ poly(x, input$piecewise_deg), data = x), silent = TRUE)
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
		theme_light_bl()

	output$pieces <- renderPlot({
		cuts <- c(0, sort(input$cuts), 60)
		piece_cols <- c("#1B9E77", "#D95F02", "#7570B3")
		piece_p <- base_p

		if (input$piecewise_deg > 0) {
			data_splt <- spline_example %>%
				dplyr::mutate(x_cut = cut(x, breaks = cuts, include.lowest = TRUE)) %>%
				tidyr::nest(.by = x_cut) %>%
				mutate(
					fit = lapply(data, maybe_lm),
					features = lapply(data, mult_poly, degree = input$piecewise_deg)
				)
			grid_splt <- dplyr::tibble(x = grid) %>%
				dplyr::mutate(x_cut = cut(x, breaks = cuts, include.lowest = TRUE)) %>%
				tidyr::nest(.by = x_cut)

			for (i in 1:3) {
				sub_pred <- grid_splt$data[[i]]
				if (!inherits(data_splt$fit[[i]], "try-error")) {
					sub_pred <- sub_pred %>%
						dplyr::bind_cols(
							predict(
								data_splt$fit[[i]],
								sub_pred,
								interval = "confidence",
								level = .90
							)
						)

					piece_p <- piece_p +
						geom_ribbon(
							data = sub_pred,
							aes(y = NULL, ymin = lwr, ymax = upr),
							alpha = 1 / 15
						) +
						geom_line(
							data = sub_pred,
							aes(y = fit),
							linewidth = line_wd
						)
				}
			}

			set.seed(383) # to control colors
			feature_p <- data_splt %>%
				dplyr::select(features) %>%
				tidyr::unnest(features) %>%
				ggplot(aes(x = variable, y = value, col = name)) +
				geom_line(show.legend = FALSE) +
				theme_void() +
				theme(
					plot.margin = margin(t = 0, r = 0, b = -20, l = 0),
					panel.background = col_rect,
					plot.background = col_rect,
					legend.background = col_rect,
					legend.key = col_rect
				) +
				scale_color_viridis(discrete = TRUE, option = "turbo")

			p <- (feature_p / piece_p) + plot_layout(heights = c(1, 4))
		}

		print(p)
	})
}
