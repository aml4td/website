# Requires the sources in shiny-setup.R

ui <- page_fillable(
	theme = grid_theme,
	padding = "1rem",
	layout_columns(
		fill = TRUE,
		column(
			width = 10,
			radioButtons(
				inputId = "method",
				label = "Embedding",
				choices = list("PCA" = "PC", "ICA" = "IC", "PLS" = "PLS"),
				inline = TRUE
			)
		)
	),

	as_fill_carrier(plotOutput("scores"))
)

server <- function(input, output) {
  load(rd_url("barley_linear_embeddings.RData"))

	output$scores <- renderPlot({
		dat <- all_scores_val %>%
			dplyr::filter(grepl(input$method, Method)) %>%
			dplyr::select(-component_num, -Method) %>%
			tidyr::pivot_wider(
				id_cols = c(barley, .row),
				names_from = label,
				values_from = value
			)

		p <- dat %>%
			ggplot(aes(x = .panel_x, y = .panel_y)) +
			geom_point(aes(col = barley), alpha = 1 / 3, cex = 1) +
			geom_autodensity(alpha = 1 / 2) +
			facet_matrix(
				vars(c(-barley, -.row)),
				layer.diag = 2,
				grid.y.diag = FALSE
			) +
			scale_color_viridis(option = "viridis") +
			theme_light_bl()

		print(p)
	})
}

app <- shinyApp(ui = ui, server = server)
