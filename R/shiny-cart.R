library(shiny)
library(ggplot2)
library(bslib)
library(viridis)


# ------------------------------------------------------------------------------

# load("/Users/max/content/website/RData/grid_cart.RData")

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
        inputId = "cost_complexity",
        label = HTML("Cost-Complexity (log<sub>10</sub>)"),
        min = -4,
        max = -1,
        value = -4,
        width = "100%",
        step = 0.5
      )
    ), 
    
    column(
      width = 6,
      sliderInput(
        inputId = "min_n",
        label = HTML("Min n"),
        min = 4L,
        max = 20L,
        value = -2,
        width = "100%",
        step = 4L
      )
    ),
    fluidRow(
      column(
        width = 4,
        sliderInput(
          inputId = "tree_depth",
          label = "(Max) Tree Depth",
          min = 1L,
          max = 10L,
          value = 10L,
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
        grid_cart[
          grid_cart$cost_complexity == input$cost_complexity & 
            grid_cart$min_n == input$min_n &
            grid_cart$tree_depth == input$tree_depth,]
      
      if (input$data_set == "validation") {
        plot_data <- example_val
      } else {
        plot_data <- example_train
      }
      
      # TODO modularize this
      p <- 
        ggplot(plot_data, aes(predictor_1, predictor_2)) +
        geom_raster(
          data = grd, 
          aes(fill = .pred_class),
          alpha = 1 / 20, 
          show.legend = FALSE
        ) +
        geom_point(aes(col = class, pch = class), cex = 2, 
                   alpha = 3 / 4) +        
        geom_contour(
          data = grd, 
          aes(z = .pred_event),
          breaks = c(-Inf, 1 / 2, Inf),
          col = "black",
          linewidth = 1, 
          show.legend = FALSE
        ) +
        coord_equal() +
        # theme_light_bl() +
        theme(legend.position = "top") +
        labs(x = "Predictor 1", y = "Predictor 2")
      
      p
      
    },
    height = 400, width = 400)
}

shinyApp(ui, server)
