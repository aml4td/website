library(shiny)
library(bslib)
library(tidymodels)

light_bg <- "#fcfefe" # from aml4td.scss
grid_theme <- bs_theme(
  bg = light_bg, fg = "#595959"
)

theme_light_bl<- function(...) {
  
  ret <- ggplot2::theme_bw(...)
  
  col_rect <- ggplot2::element_rect(fill = light_bg, colour = light_bg)
  ret$panel.background  <- col_rect
  ret$plot.background   <- col_rect
  ret$legend.background <- col_rect
  ret$legend.key        <- col_rect
  
  ret$legend.position <- "top"
  
  ret
}

ui <- page_fillable(
  theme = bs_theme(bg = "#fcfefe", fg = "#595959"),
  padding = "1rem",
  layout_columns(
    fill = FALSE,
    col_widths = breakpoints(xs = c(-3, 6, -3), sm = 4),
    column(
      width = 12,
      sliderInput(
        "gen",
        label = "Generation",
        min = 1L,
        max = 10L,
        step = 1L,
        value = 1L
      )
    )
  ),
  as_fill_carrier(plotOutput("generations"))
)

server <- function(input, output) {
  
  # load(url("https://raw.githubusercontent.com/aml4td/website/main/RData/barley_linear_embeddings.RData"))
  load("../RData/two_param_iter_ga.RData")
  ga_history$RMSE <- ga_history$fitness

  # ------------------------------------------------------------------------------
  x_rng <- 10^extendrange(c(-10, -1/10))
  y_rng <- 2^extendrange(c(-10, 10))
  
  output$generations <-
    renderPlot({
      p <- 
        ga_history %>%
        filter(generation == input$gen) %>%
        ggplot(aes(scale_factor, cost)) +
        geom_point(aes(col = RMSE), alpha = 1/2, cex = 3) +
        scale_x_log10(limits = x_rng) +
        scale_y_continuous(trans = "log2", limits = y_rng) +
        theme_bw() +
        theme(legend.position = "top") +
        labs(x = "Scaling Factor", y = "Cost") +
        coord_fixed(ratio = 1/2) +
        scale_fill_distiller(palette = "Blues", type = "seq", 
                             direction = -1, transform = "log") +
        theme(legend.text = element_blank())
      print(p)
      
    })
}

app <- shinyApp(ui, server)
