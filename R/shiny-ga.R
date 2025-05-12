# Requires the sources in shiny-setup.R

ui <- page_fillable(
#	theme = grid_theme,
	sliderInput(
		"gen",
		label = "Generation",
		min = 1L,
		max = 7L,
		step = 1L,
		value = 1L,
		width = "100%"
	),
	as_fill_carrier(plotOutput("generations"))
)

server <- function(input, output) {
  rd_url <- function(nm) {
    rd_base <- "https://raw.githubusercontent.com/aml4td/website/main/RData"
    url(file.path(rd_base, nm))
  }
  
	num_cuts <- 50
	rd_or <- colorRampPalette(rev(RColorBrewer::brewer.pal(9, "OrRd")))(num_cuts)

	load(rd_url("two_param_iter_ga.RData"))
	load(rd_url("two_param_iter_large.RData"))

	ga_history$mean <- ga_history$fitness
	ga_history <- ga_history %>%
		mutate(RMSE = cut(mean, breaks = seq(5, 31, length = num_cuts)))

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

	output$generations <- renderPlot(
		{
			last_best <- ga_history %>%
				filter(generation <= input$gen) %>%
				slice_min(mean)

			current_gen <- ga_history %>% filter(generation == input$gen)

			p <- ga_history %>%
				ggplot(aes(scale_factor, cost)) +
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
				geom_point(
					data = current_gen,
					aes(col = RMSE),
					alpha = 2 / 4,
					cex = 2,
					show.legend = FALSE
				) +
				geom_point(
					data = last_best,
					cex = 4,
					aes(col = RMSE),
					pch = 8,
					show.legend = FALSE
				) +
				labs(x = "Scaling Factor", y = "Cost") +
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
				theme(legend.location = "none")

			print(p)
		},
		res = 100
	)
}

app <- shinyApp(ui, server)
