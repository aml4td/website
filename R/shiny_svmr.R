library(shiny)
library(ggplot2)
library(bslib)
library(viridis)


# ------------------------------------------------------------------------------

load("../RData/grid_svmr.RData")
load("../RData/example_class.RData")
source("shiny_themes.R")

# ------------------------------------------------------------------------------

shiny_cls_cols <- c("#4151B0FF",  "#D0641EFF")

# ------------------------------------------------------------------------------

ui <- fluidPage(
  theme = grid_theme,
  fluidRow(
    
    column(
      width = 6,
      sliderInput(
        inputId = "cost",
        label = HTML("Cost (log<sub>2</sub>)"),
        min = 5,
        max = 25,
        value = 5,
        width = "100%",
        step = 1
      )
    ), # cost
    
    column(
      width = 6,
      sliderInput(
        inputId = "rbf_sigma",
        label = HTML("RBF (log<sub>10</sub>)"),
        min = -5,
        max = 2,
        value = 0,
        width = "100%",
        step = 1
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
        grid_svmr[
          grid_svmr$cost == input$cost & 
            grid_svmr$rbf_sigma == input$rbf_sigma,]
      
      if (input$data_set == "validation") {
        plot_data <- example_val
      } else {
        plot_data <- example_train
      }
      
      grd$`decision value` <- grd$pred
      
      p <- 
        ggplot(plot_data, aes(predictor_1, predictor_2)) +
        geom_raster(
          data = grd, 
          aes(fill = `decision value`),
          alpha = 1 / 2
        ) +
        geom_point(aes(col = class, pch = class), cex = 2, alpha = 3 / 4, show.legend = FALSE) +        
        geom_contour(
          data = grd, 
          aes(z = pred),
          breaks = c(-Inf, 0, Inf),
          col = "black",
          linewidth = 1, 
          show.legend = FALSE
        ) +
        coord_equal() +
        theme(legend.position = "top") +
        scale_fill_gradient2(
          midpoint = 0,
          low = shiny_cls_cols[1],
          high = shiny_cls_cols[2]
        ) +
        scale_color_manual(values = shiny_cls_cols) + 
        labs(x = "Predictor 1", y = "Predictor 2") 
      
      p
    },
    height = 400, width = 400)
}

shinyApp(ui, server)
