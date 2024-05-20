library(shiny)
library(ggplot2)
library(bslib)
library(viridis)
library(tune)

# ------------------------------------------------------------------------------

load("../RData/grid_knn.RData")
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
        inputId = "neighbors",
        label = "Neighbors",
        min = 1,
        max = 21,
        value = 5,
        width = "100%",
        step = 2
      )
    ), # nearest neighbors
    
    column(
      width = 6,
      sliderInput(
        inputId = "dist_power",
        label = "Power",
        min = 0.5,
        max = 2,
        value = 1,
        width = "100%",
        step = 0.25
      )
    ),
    fluidRow(
      column(
        width = 4,
        radioButtons(
          inputId = "weight_func",
          label = "Weighting",
          choices = list("Rectangular" = "rectangular", "Triangular" = "triangular", 
                         "Gaussian" = "gaussian")
        ),
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
        grid_knn[
          grid_knn$weight_func == input$weight_func & 
            grid_knn$dist_power == input$dist_power & 
            grid_knn$neighbors == input$neighbors,]
      
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
