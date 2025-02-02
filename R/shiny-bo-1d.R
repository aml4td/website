ui <- page_fillable(
  theme = bs_theme(bg = "#fcfefe", fg = "#595959"),
  sliderInput(
    "iteration",
    label = "Iterations",
    min = 1L,
    max = 15L,
    step = 1L,
    value = 1L,
    width = "100%"
  ),
  as_fill_carrier(plotOutput("iterations"))
)

server <- function(input, output) {
  
  y_rng <- extendrange(true_curve$y)
  p_base <- 
    ggplot(true_curve, aes(x = x)) +
    geom_line(aes(y = y), alpha = 1 / 10, linewidth = 1) +
    labs(x = "Parameter", y = "Objective Function") +
    lims(y = y_rng) +
    theme_bw()
  
  output$iterations <-
    renderPlot({
      
      plot_data <- obs_dat[obs_dat$iteration < input$iteration, ]
      next_data <- obs_dat[obs_dat$iteration == input$iteration, ]
      plot_curve <- gp_pred[[input$iteration]]
      plot_curve$`Std Dev` <- plot_curve$.sd
      
      p <- 
        p_base +
        geom_line(data = plot_curve, aes(y = .mean, col = `Std Dev`), 
                  alpha = 1, linewidth = 1.2) +
        geom_point(data = plot_data, aes(y = y), cex = 2) +
        geom_vline(xintercept = next_data$x, col = "red", lty = 2) +
        scale_colour_viridis_c(option = "mako", direction = -1) +
        theme(
          plot.margin = margin(t = 0.0, r = 5.5, b = 5.5, l = 5.5, unit = "pt")
        )
      
      p_ei <- 
        ggplot(plot_curve, aes(x = x, y = objective)) + 
        geom_line() +
        geom_vline(xintercept = next_data$x, col = "red", lty = 2) + 
        lims(y = 0:1) + 
        labs(y = "Expected Imp.", x = NULL) + 
        theme_bw() +
        theme(
          axis.text.x = element_blank(), axis.ticks.x = element_blank(),
          plot.margin = margin(t = 5.5, r = 5.5, b = 0.0, l = 5.5, unit = "pt")
        ) 
      
      print((p_ei / p) + plot_layout(heights = c(2, 3)))
      
    }, res = 100)
}

app <- shinyApp(ui, server)
