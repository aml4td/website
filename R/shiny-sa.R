# Requires the sources in shiny-setup.R

ui <- page_fillable(
	theme = grid_theme,
	sliderInput(
		"iter",
		label = "Iteration",
		min = 1L,
		max = 50L,
		step = 1L,
		value = 1L,
		width = "100%"
	),
	as_fill_carrier(plotOutput("path")),
	renderText("notes")
)

server <- function(input, output) {
	load(rd_url("two_param_iter_sa.RData"))
	load(rd_url("two_param_iter_large.RData"))
	
	num_cuts <- 50
	rd_or <- colorRampPalette(rev(RColorBrewer::brewer.pal(9, "OrRd")))(num_cuts)

	# ------------------------------------------------------------------------------

	x_rng <- 10^extendrange(c(-10, -1 / 10))
	y_rng <- 2^extendrange(c(-10, 10))

	log10_labs <- trans_format(
		"log10",
		math_format(10^.x, function(x) format(x, digits = 3))
	)
	log2_labs <- trans_format(
		"log2",
		math_format(2^.x, function(x) format(x, digits = 3))
	)

	# ------------------------------------------------------------------------------

	sa_history <- sa_history %>%
		mutate(RMSE = cut(mean, breaks = seq(5, 31, length = num_cuts)))

	# TODO pre-compute these
	sa_init <- sa_history %>%
		filter(.iter == 0)
	best_init <- sa_init %>%
		slice_min(mean) %>%
		select(.iter, cost, scale_factor, RMSE)
	poor_init <- anti_join(
		sa_init,
		best_init,
		by = c(".iter", "cost", "scale_factor")
	) %>%
		select(.iter, cost, scale_factor)

	initial_plot <- regular_mtr %>%
		mutate(RMSE = cut(mean, breaks = seq(5, 31, length = num_cuts))) %>%
		ggplot(aes(scale_factor, cost, col = RMSE)) +
		geom_point(data = sa_init, cex = 3, pch = 1, col = "black") +
		geom_line(
			data = regular_mtr %>% slice_min(mean, n = 18),
			stat = "smooth",
			col = "black",
			method = lm,
			se = FALSE,
			formula = y ~ x,
			alpha = 1 / 8,
			linewidth = 2
		) +
		scale_x_log10(
			limits = x_rng,
			labels = log10_labs,
			expand = expansion(add = c(-1 / 5, -1 / 5))
		) +
		scale_y_continuous(
			limits = y_rng,
			trans = "log2",
			labels = log2_labs,
			expand = expansion(add = c(-1 / 2, -1 / 2))
		) +
		scale_color_manual(values = rd_or, drop = FALSE) +
		coord_fixed(ratio = 1 / 2) +
		theme_bw() +
		theme(legend.position = "none")

	# ------------------------------------------------------------------------------

	output$path <- renderPlot(
		{
			current_path <- paths[[input$iter]] %>%
				mutate(
					mean = RMSE,
					RMSE = cut(RMSE, breaks = seq(5, 31, length = num_cuts))
				)
			last_best <- iter_best[[input$iter]] %>%
				mutate(RMSE = cut(mean, breaks = seq(5, 31, length = num_cuts)))

			last_best_iter <- last_best %>%
				pluck(".iter")

			lab <- iter_label[[input$iter]]

			current_plot <- initial_plot +
				geom_path(data = current_path, col = "black", alpha = 1 / 5) +
				geom_point(
					data = current_path %>% filter(.iter > 0),
					aes(scale_factor, cost, col = RMSE),
					cex = 2
				) +
				geom_point(
					data = last_best,
					cex = 4,
					aes(col = RMSE),
					pch = 8,
					show.legend = FALSE
				) +
				labs(x = "Scaling Factor", y = "Cost", title = lab)

			print(current_plot)
		},
		res = 100
	)

	output$notes <- renderText({
		current_path <- resolve_sa_path(sa_history, input$iter) %>%
			anti_join(poor_init, by = c(".iter", "cost", "scale_factor"))
		describe_result(current_path)
	})
}

app <- shinyApp(ui, server)
