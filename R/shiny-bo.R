# Requires the sources in shiny-setup.R

ui <- page_fillable(
#	theme = grid_theme,
	sliderInput(
		"iter",
		label = "Iteration",
		min = 1L,
		max = 50L,
		step = 1L,
		value = 1L,
		width = "100%"
	),
	radioButtons(
		inputId = "objective",
		label = "Objective Function",
		inline = TRUE,
		choices = list(
			"Exp. Improivement" = "objective",
			"Mean" = ".mean",
			"Std. Dev" = ".sd"
		)
	),
	as_fill_carrier(plotOutput("path"))
)

server <- function(input, output) {

  rd_url <- function(nm) {
    rd_base <- "https://raw.githubusercontent.com/aml4td/website/main/RData"
    url(file.path(rd_base, nm))
  }
  
  load(rd_url("two_param_iter_bo.RData"))
  load(rd_url("two_param_iter_large.RData"))

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

	best_init <- bo_mtr %>%
		filter(.iter == 0) %>%
		slice_min(mean) %>%
		select(cost, scale_factor, .iter)

	initial_plot <- regular_mtr %>%
		ggplot(aes(scale_factor, cost)) +
		geom_point(data = init_grid, cex = 3, pch = 1) +
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
		theme_bw() +
		labs(x = "Scaling Factor", y = "Cost") +
		coord_fixed(ratio = 1 / 2)

	bo_tile <- tidyr::pivot_longer(
		bo_tile,
		cols = c(.mean, .sd, objective),
		names_to = "metric",
		values_to = "value"
	)

	# ------------------------------------------------------------------------------

	output$path <- renderPlot(
		{
			tile <- bo_tile %>%
				filter(.iter == input$iter & metric == input$objective)
			last_best <- bo_mtr %>% filter(.iter < input$iter) %>% slice_min(mean)
			path <- bo_mtr %>%
				filter(.iter <= input$iter & .iter > 0) %>%
				select(cost, scale_factor, .iter) %>%
				bind_rows(best_init) %>%
				arrange(.iter)

			# TODO convert to discrete colors via cut
			rc_pal <- switch(
				input$objective,
				"objective" = "Greens",
				".mean" = "OrRd",
				".sd" = "Blues"
			)

			hist_alpha <- case_when(
				input$iter < 5 ~ 1 / 2,
				input$iter >= 5 & input$iter < 10 ~ 1 / 3,
				input$iter >= 10 & input$iter < 20 ~ 1 / 4,
				input$iter >= 20 & input$iter < 30 ~ 1 / 5,
				TRUE ~ 1 / 10
			)
			hist_alpha <- 2 * hist_alpha

			col_dir <- if_else(input$objective == ".mean", -1, 1)
			col_tr <- "identity"

			current_plot <- initial_plot +
				geom_tile(data = tile, aes(fill = value), alpha = 1 / 2) +
				geom_line(
					data = regular_mtr %>% slice_min(mean, n = 18),
					stat = "smooth",
					col = "black",
					method = lm,
					se = FALSE,
					formula = y ~ x,
					alpha = 1 / 4,
					linewidth = 2
				) +
				geom_path(data = path, col = "black", alpha = hist_alpha, lty = 3) +
				geom_point(
					data = new_bo_points %>% filter(iter == input$iter),
					col = "black",
					pch = 16,
					cex = 4
				) +
				geom_point(data = last_best, cex = 4, col = "black", pch = 8) +
				scale_fill_distiller(
					palette = rc_pal,
					type = "seq",
					direction = col_dir,
					transform = col_tr
				) +
				theme(legend.title = element_blank(), legend.text = element_blank())
			print(current_plot)
		},
		res = 100
	)
}

app <- shinyApp(ui, server)
