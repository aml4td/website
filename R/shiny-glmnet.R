library(shiny)
library(ggplot2)
library(bslib)
library(viridis)
library(tune)

# ------------------------------------------------------------------------------

load("../RData/grid_glmnet.RData")
source("shiny_cls_boundary_plot.R")

# ------------------------------------------------------------------------------

light_bg <- "#fcfefe" # from aml4td.scss
grid_theme <- bs_theme(
  bg = light_bg, fg = "#595959"
)

# ------------------------------------------------------------------------------

ui <- fluidPage(
  theme = grid_theme,
  fluidRow(
    
    column(
      width = 6,
      sliderInput(
        inputId = "penalty",
        label = HTML("Penalty (log<sub>10</sub>)"),
        min = -3,
        max = 0,
        value = -1,
        width = "100%",
        step = 0.5
      )
    ), 
    
    column(
      width = 6,
      sliderInput(
        inputId = "mixture",
        label = "L1 Proportion",
        min = 0,
        max = 1,
        value = 1/2,
        width = "100%",
        step = 1/4
      )
    ),
    fluidRow(
      column(
        width = 4,
        sliderTextInput(
          inputId = "x1",
          label = "Spline Degree (x1)",
          choices = c(0, 5, 10, 20),
          selected = 10,
          grid = TRUE
        ),
        sliderTextInput(
          inputId = "x2",
          label = "Spline Degree (x2)",
          choices = c(0, 5, 10, 20),
          selected = 10,
          grid = TRUE
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
        grid_glmnet[
          grid_glmnet$penalty == input$penalty & 
            grid_glmnet$mixture == input$mixture &
            grid_glmnet$x1 == input$x1 &
            grid_glmnet$x2 == input$x2,]
      
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
