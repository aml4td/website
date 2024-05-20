library(shiny)
library(ggplot2)
library(bslib)
library(viridis)

# ------------------------------------------------------------------------------

load("../RData/grid_mlp.RData")
load("../RData/example_class.RData")
source("shiny_themes.R")
source("shiny_cls_boundary_plot.R")

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
        inputId = "hidden_units",
        label = "Hidden units",
        min = 2,
        max = 10,
        value = 2,
        width = "100%",
        step = 1
      )
    ), # hidden_units
    
    column(
      width = 6,
      sliderInput(
        inputId = "penalty",
        label = HTML("Weight Decay (log<sub>10</sub>)"),
        min = -4,
        max = -1,
        value = -4,
        width = "100%",
        step = 1
      )
    ),
    fluidRow(
      column(
        width = 4,
        sliderInput(
          inputId = "learn_rate",
          label = HTML("Learning Rate (log<sub>10</sub>)"),
          min = -4,
          max = -1,
          value = -1,
          width = "100%",
          step = 1
        ),
        radioButtons(
          inputId = "activation",
          label = "Activation",
          choices = list("celu", "tanh", "relu", "sigmoid")
        ),
        radioButtons(
          inputId = "stop_iter",
          label = "Early Stopping",
          choices = list("yes", "no")
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

      stop_iter <- ifelse(input$stop_iter == "yes", 5, Inf)

      grd <- 
        grid_mlp[
          grid_mlp$penalty == input$penalty & 
            grid_mlp$activation == input$activation & 
            grid_mlp$hidden_units == input$hidden_units & 
            grid_mlp$learn_rate == input$learn_rate &
            grid_mlp$stop_iter == stop_iter,]
      
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
