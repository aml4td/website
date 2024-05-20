library(shiny)
library(ggplot2)
library(bslib)
library(viridis)
library(tune)

# ------------------------------------------------------------------------------

load("../RData/grid_nbayes.RData")
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
        inputId = "smoothness",
        label = "Smoothness",
        min = 0.25,
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
      
      grd <- grid_nbayes[grid_nbayes$smoothness == input$smoothness ,]
      
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
