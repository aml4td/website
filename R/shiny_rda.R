library(shiny)
library(ggplot2)
library(bslib)
library(viridis)
library(tune)

# ------------------------------------------------------------------------------

load("../RData/grid_mars.RData")
load("../RData/example_class.RData")
source("shiny_themes.R")
source("shiny_cls_boundary_plot.R")

# ------------------------------------------------------------------------------

ui <- fluidPage(
  theme = grid_theme,
  fluidRow(
    
    column(
      width = 6,
      sliderInput(
        inputId = "frac_common_cov",
        label = "Common Covariance",
        min = 0,
        max = 1,
        value = 1,
        width = "100%",
        step = 0.2
      )
    ), # frac_common_cov
    
    column(
      width = 6,
      sliderInput(
        inputId = "frac_identity",
        label = "Shrinkage Towards Identity",
        min = 0,
        max = 1,
        value = 1,
        width = "100%",
        step = 0.2
      )
    ),
    fluidRow(
      column(
        width = 4,
        radioButtons(
          inputId = "data_set",
          label = "Show Data",
          choices = list("Training" = "training", "Validation" = "validation"),
          selected = "validation"
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
      
      grd <- 
        grid_rda[
          grid_rda$frac_common_cov == input$frac_common_cov & 
            grid_rda$frac_identity == input$frac_identity,]
      
      if (input$data_set == "validation") {
        plot_data <- example_val
      } else {
        plot_data <- example_train
      }
      
      plot_boundary(plot_data, grd)
      
    },
    height = 400, width = 400)
}

shinyApp(ui, server)
