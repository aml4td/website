# Requires the sources in shiny-setup.R

ui <- fluidPage(
	theme = grid_theme,
	fluidRow(
		column(
			width = 4,
			sliderInput(
				inputId = "min_dist",
				label = "Min Distance",
				min = 0.0,
				max = 1.0,
				value = 0.2,
				width = "100%",
				step = 0.2
			)
		), # min distance
		column(
			width = 4,
			sliderInput(
				inputId = "neighbors",
				label = "Neighbors",
				min = 5,
				max = 45,
				value = 5,
				width = "100%",
				step = 10
			)
		), # nearest neighbors

		column(
			width = 4,
			sliderInput(
				inputId = "supervised",
				label = "Amount of Supervision",
				min = 0.0,
				max = 0.7,
				value = 0,
				width = "100%",
				step = 0.1
			)
		),
		fluidRow(
			column(
				width = 4,
				radioButtons(
					inputId = "initial",
					label = "Initialization",
					choices = list(
						"Laplacian Eigenmap" = "spectral",
						"PCA" = "pca",
						"Random" = "random"
					)
				)
			),
			column(
				width = 6,
				align = "center",
				plotOutput('umap')
			)
		)
	) # top fluid row
)

server <- function(input, output) {

  load(rd_url("umap_results.RData"))

	output$umap <- renderPlot({
		dat <- umap_results[
			umap_results$neighbors == input$neighbors &
				umap_results$min_dist == input$min_dist &
				umap_results$initial == input$initial &
				# log10(umap_results$learn_rate) == input$learn_rate &
				umap_results$supervised == input$supervised,
		]

		p <- ggplot(dat, aes(UMAP1, UMAP2, col = barley)) +
			geom_point(alpha = 1 / 3, cex = 3) +
			scale_color_viridis(option = "viridis") +
			theme_light_bl() +
			coord_fixed() +
			labs(x = "UMAP Embedding #1", y = "UMAP Embedding #2") +
			guides(col = guide_colourbar(barheight = 0.5))

		print(p)
	})
}

app <- shinyApp(ui = ui, server = server)
