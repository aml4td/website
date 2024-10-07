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
  
  # load(url("https://raw.githubusercontent.com/aml4td/website/main/RData/barley_linear_embeddings.RData"))
  load("../RData/two_param_iter_sa.RData")
  
  # ------------------------------------------------------------------------------
  
  x_rng <- 10^extendrange(c(-10, -1/10))
  y_rng <- 2^extendrange(c(-10, 10))
  
  log10_labs <- trans_format("log10", math_format(10^.x, function(x) format(x, digits = 3)))
  log2_labs <- trans_format("log2", math_format(2^.x, function(x) format(x, digits = 3)))

  # ------------------------------------------------------------------------------
  
  # TODO pre-compute these
  sa_init <- 
    sa_history %>% 
    filter(.iter == 0) %>% 
    rename(RMSE = mean)
  best_init <- 
    sa_init %>% 
    slice_min(RMSE) %>% 
    select(.iter, cost, scale_factor)
  poor_init <- 
    anti_join(sa_init, best_init, by = c(".iter", "cost", "scale_factor")) %>% 
    select(.iter, cost, scale_factor)
  
  initial_plot <- 
    sa_history %>%
    ggplot(aes(scale_factor, cost)) +
    geom_point(data = sa_init, cex = 5, pch = 1, col = "black") +
    scale_x_log10(limits = x_rng, , labels = log10_labs) +
    scale_y_continuous(trans = "log2", labels = log2_labs) +
    theme_bw() +
    labs(x = "Scaling Factor", y = "Cost") +
    coord_fixed(ratio = 1/2) +
    scale_fill_distiller(palette = "Blues", type = "seq", 
                         direction = -1, transform = "log") +
    theme(legend.text = element_blank())
  
  # ------------------------------------------------------------------------------
  
  output$path <-
    renderPlot({
      
      # TODO pre-compute these
      current_path <- paths[[input$iter]]
      last_best <- iter_best[[input$iter]]
      
      last_best_iter <-
        last_best %>% 
        pluck(".iter")

      lab <- iter_label[[input$iter]]
      
      current_plot <- 
        initial_plot +
        geom_path(data = current_path, col = "black", alpha = 1 / 5) +
        geom_point(
          data = current_path %>% filter(.iter > 0),
          aes(scale_factor, cost, col = RMSE),
          cex = 3
        ) +
        geom_point(data = last_best, cex = 4, col = "black", pch = 8) +
        labs(title = lab)
      
      print(current_plot)
      
    })
  
  output$notes <-
    renderText({
      current_path <- 
        resolve_sa_path(sa_history, input$iter) %>% 
        anti_join(poor_init, by = c(".iter", "cost", "scale_factor"))
      describe_result(current_path)
    })
}

app <- shinyApp(ui, server)
