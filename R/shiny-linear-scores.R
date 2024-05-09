library(shiny)
library(ggplot2)
library(bslib)
library(viridis)
library(dplyr)
library(tidyr)
library(purrr)
library(ggforce)

# ------------------------------------------------------------------------------

light_bg <- "#fcfefe" # from aml4td.scss
grid_theme <- bs_theme(
  bg = light_bg, fg = "#595959"
)

# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------

ui <- page_fillable(
  theme = bs_theme(bg = "#fcfefe", fg = "#595959"),
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
  load(url("https://raw.githubusercontent.com/aml4td/website/main/RData/barley_linear_embeddings.RData"))
  
  
  output$scores <-
    renderPlot({
      dat <- 
        all_scores_val %>% 
        dplyr::filter(grepl(input$method, Method)) %>% 
        dplyr::select(-component_num, -Method) %>% 
        tidyr::pivot_wider(id_cols = c(barley, .row), names_from = label, values_from = value)
      
      p <- dat %>% 
        ggplot(aes(x = .panel_x, y = .panel_y)) + 
        geom_point(aes(col = barley), alpha = 1 / 3, cex = 1) + 
        geom_autodensity(alpha = 1 / 2) +
        facet_matrix(vars(c(-barley, -.row)), layer.diag = 2, grid.y.diag = FALSE) +
        scale_color_viridis(option = "viridis") +
        theme_light_bl()

      
      print(p)
      
    })
  
}

app <- shinyApp(ui = ui, server = server)
