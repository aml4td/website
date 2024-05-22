library(shiny)
library(ggplot2)
library(bslib)
library(viridis)
library(shinyWidgets)

# ------------------------------------------------------------------------------

load("../RData/grid_mlp.RData")
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
        inputId = "hidden_units",
        label = "Hidden units",
        min = 5,
        max = 95,
        value = 5,
        width = "100%",
        step = 10
      )
    ), # hidden_units
    
    column(
      width = 6,
      sliderTextInput(
        inputId = "penalty",
        label = HTML("Weight Decay (log<sub>10</sub>)"),
        choices = c(0, 10^(-5:-2)),
        selected = 0,
        grid = TRUE
      )
      
    ),
    fluidRow(
      column(
        width = 4,
        sliderInput(
          inputId = "learn_rate",
          label = HTML("Learning Rate (log<sub>10</sub>)"),
          min = -3,
          max = -1,
          value = -1,
          width = "100%",
          step = 1
        ),
        radioButtons(
          inputId = "activation",
          label = "Activation",
          choices = list("tanh", "relu", "gelu")
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

      penaly <- ifelse(input$penalty > 0, log10(input$penalty), 0)
      
      grd <- 
        grid_mlp[
          grid_mlp$penalty == penaly & 
            grid_mlp$activation == input$activation & 
            grid_mlp$hidden_units == input$hidden_units & 
            grid_mlp$learn_rate == input$learn_rate,]
      
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
