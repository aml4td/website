
ui <- page_fillable(
  theme = bs_theme(),
  bslib::input_dark_mode(),
  padding = "1rem",
  layout_columns(
    fill = FALSE,
    col_widths = breakpoints(xs = c(-2, 4, 4, -2), sm = 4),
    column(
      width = 4,
      checkboxGroupInput(
        inputId = "method",
        label = "Embedding",
        choices = list("PCA" = "pca", "ICA" = "ica", "PLS" = "pls"),
        selected = "pca"
      )
    ),
    column(
      width = 4,
      checkboxGroupInput(
        inputId = "comps",
        label = "Component",
        choices = list("1" = "1", "2" = "2", "3" = "3", "4" = "4"),
        selected = paste0(1:4),
        inline = TRUE
      )
    )
  ),
  as_fill_carrier(plotOutput("loadings"))
)


server <- function(input, output) {
  load(url("https://raw.githubusercontent.com/aml4td/website/main/RData/barley_linear_embeddings.RData"))
  
  theme_set(theme_transparent())
  
  # ------------------------------------------------------------------------------
  
  output$loadings <-
    renderPlot({
      dat <- 
        all_loadings %>% 
        dplyr::filter(id %in% input$method & component_number %in% input$comps)
      p <-
        ggplot(dat, aes(x = wavelength, y = value, col = component_number)) +
        geom_hline(yintercept = 0, lty = 3) +
        geom_line(alpha = 3 / 4, linewidth = 1) +
        labs(y = "Loading Value") +
        scale_color_brewer(palette = "Dark2") 
      
      if ( length(input$method) > 1) {
        p <- p + facet_wrap(~ id, nrow = 1)
      }
      print(p)
    }, 
    bg = NA)
}

app <- shinyApp(ui = ui, server = server)
