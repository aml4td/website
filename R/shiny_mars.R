library(shiny)
library(ggplot2)
library(bslib)
library(viridis)


# ------------------------------------------------------------------------------

load("/Users/max/content/website/RData/demo_data.RData")
load("/Users/max/content/website/RData/demo_grid.RData")
load("/Users/max/content/website/RData/grid_mars.RData")

set.seed(986)
split <- initial_split(demo_data, prop = 2 / 3, strata = class)
demo_tr <- training(split)
demo_te <- testing(split)
rngs <- list(x = range(demo_data$predictor_1), y = range(demo_data$predictor_2))



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

ui <- fluidPage(
  theme = grid_theme,
  fluidRow(
    
    column(
      width = 6,
      sliderInput(
        inputId = "num_terms",
        label = "Number of Terms",
        min = 2,
        max = 10,
        value = 3,
        width = "100%",
        step = 1
      )
    ), # num_terms
    fluidRow(
      column(
        width = 4,
        radioButtons(
          inputId = "prod_degree",
          label = "Initialization",
          choices = list("Additive" = "additive", "Interactions" = "interactions")
        ),
        radioButtons(
          inputId = "data_set",
          label = "Show Data",
          choices = list("Training" = "training", "Testing" = "testing"),
          selected = "testing"
        )
      ),
      column(
        width = 6,
        align = "center",
        plotOutput('contours', width = "100%")
      )
    )
  ) # top fluid row
)


server <- function(input, output) {
  
  
  output$contours <-
    renderPlot({
      
      prod_degree <- ifelse(input$prod_degree == "additive", 1, 2)
      
      grd <- 
        grid_mars[
          grid_mars$prod_degree == prod_degree & 
            grid_mars$num_terms == input$num_terms ,]
      
      if (input$data_set == "testing") {
        plot_data <- demo_te
      } else {
        plot_data <- demo_tr
      }
      
      
      p <- 
        ggplot(plot_data, aes(predictor_1, predictor_2)) +
        geom_point(aes(col = class, pch = class), cex = 2, 
                   alpha = 1 / 2) +
        geom_contour(
          data = grd, 
          aes(z = .pred_A),
          breaks = c(-Inf, 1 / 2, Inf),
          col = "black",
          linewidth = 1
        ) +
        
        # coord_equal() +
        theme(legend.position = "top") +
        lims(x = rngs$x, y = rngs$y) +
        labs(x = "Predictor 1", y = "Predictor 2")
      
      p
      
    },
    height = 400, width = 400)
}

shinyApp(ui, server)
