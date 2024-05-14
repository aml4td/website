library(shiny)
library(ggplot2)
library(bslib)
library(viridis)
library(shinyWidgets)

# ------------------------------------------------------------------------------

# load("/Users/max/content/website/RData/grid_xrf.RData")

# ------------------------------------------------------------------------------

light_bg <- "#fcfefe" # from aml4td.scss
grid_theme <- bs_theme(
  bg = light_bg, fg = "#595959"
)

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
      sliderTextInput(
        inputId = "trees",
        label = "#Trees",
        choices = c(1, 10, 25, 50),
        selected = 10,
        grid = TRUE
      )
    ), # trees
    
    column(
      width = 6,
      sliderTextInput(
        inputId = "min_n",
        label = "Min Points",
        choices = c(2, 10, 25),
        selected = 10,
        grid = TRUE
      )
    )
  ),
  fluidRow(
    column(
      width = 6,
      sliderInput(
        inputId = "learn_rate",
        label = HTML("Learning Rate (log<sub>10</sub>)"),
        min = -4,
        max = -1,
        value = -1,
        width = "100%",
        step = 1
      )
    ),
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
    )
  ),
  fluidRow(
    column(
      width = 4,
      sliderInput(
        inputId = "tree_depth",
        label = "Tree Depth",
        min = 1,
        max = 5,
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


server <- function(input, output) {
  
  output$contours <-
    renderPlot({
      
      grd <- 
        grid_xrf[
          grid_xrf$penalty == input$penalty & 
            grid_xrf$min_n == input$min_n & 
            grid_xrf$trees == input$trees & 
            grid_xrf$learn_rate == input$learn_rate &
            grid_xrf$tree_depth == input$tree_depth,]
      
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
        geom_point(aes(col = class, pch = class), cex = 2, alpha = 3 / 4) +        
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
