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
        inputId = "num_terms",
        label = "Number of Terms",
        min = 2,
        max = 20,
        value = 10,
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
      
      prod_degree <- ifelse(input$prod_degree == "additive", 1, 2)
      
      grd <- 
        grid_mars[
          grid_mars$prod_degree == prod_degree & 
            grid_mars$num_terms == input$num_terms ,]
      
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
