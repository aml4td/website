# Requires the sources in shiny-setup.R

ui <- page_fillable(
#	theme = grid_theme,
	padding = "1rem",
	layout_columns(
		fill = FALSE,
		col_widths = breakpoints(xs = c(-2, 8, -2), sm = 4),
		sliderInput(
			"beta_1",
			label = "Predictor 1 slope",
			min = -4.0,
			max = 4.0,
			step = 0.5,
			value = 1
		),
		sliderInput(
			"beta_2",
			label = "Predictor 2 slope",
			min = -4.0,
			max = 4.0,
			step = 0.5,
			value = 1
		),
		sliderInput(
			"beta_int",
			label = "Interaction slope",
			min = -2.0,
			max = 2.0,
			step = 0.25,
			value = 0.5
		)
	),
	as_fill_carrier(plotOutput("contours"))
)

server <- function(input, output) {
	# ------------------------------------------------------------------------------

	n_grid <- 100
	grid_1d <- seq(-1, 1, length.out = n_grid)
	grid <- expand.grid(A = grid_1d, B = grid_1d)

	output$contours <- renderPlot({
		grid$outcome <- input$beta_1 *
			grid$A +
			input$beta_2 * grid$B +
			input$beta_int * grid$A * grid$B

		p <- ggplot(grid, aes(A, B)) +
			coord_equal() +
			labs(x = "Predictor 1", y = "Predictor 1") +
			theme_light_bl()

		if (length(unique(grid$outcome)) >= 15) {
			p <- p +
				geom_contour_filled(
					aes(z = scale(outcome)),
					bins = 15,
					show.legend = FALSE
				) +
				scale_fill_viridis_d(option = "G")
		}

		print(p)
	})
}

app <- shinyApp(ui, server)
