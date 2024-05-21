library(shiny)
library(ggplot2)
library(bslib)
library(viridis)


# ------------------------------------------------------------------------------

load("../RData/grid_svmp.RData")
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
        min = -1,
        max = 15,
        value = 5,
        width = "100%",
        step = 1
      )
    ), 
    
    column(
      width = 6,
      sliderInput(
        inputId = "scale_factor",
        label = HTML("Scale (log<sub>10</sub>)"),
        min = -3,
        max =  -1,
        value = -2,
        width = "100%",
        step = 0.5
      )
    ),
    fluidRow(
      column(
        width = 4,
        sliderInput(
          inputId = "degree",
          label = "polynomial degree",
          min = 1,
          max = 4,
          value = 2,
          width = "100%",
          step = 1
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
        grid_svmp[
          grid_svmp$cost == input$cost & 
            grid_svmp$scale_factor == input$scale_factor &
            grid_svmp$degree == input$degree,]
      
      grd$`decision value` <- grd$pred
      
      if (input$data_set == "validation") {
        plot_data <- example_val
      } else {
        plot_data <- example_train
      }
      
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
        labs(x = "Predictor 1", y = "Predictor 2") +
        theme_light_bl() 
      
      p
      
    },
    height = 400, width = 400)
}

shinyApp(ui, server)
