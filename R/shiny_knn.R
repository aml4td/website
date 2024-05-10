library(shiny)
library(ggplot2)
library(bslib)
library(viridis)


# ------------------------------------------------------------------------------
load("/Users/max/content/website/RData/grid_knn.RData")




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
                         "Inverse" = "inv")
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
      
      
      p <- 
        ggplot(plot_data, aes(predictor_1, predictor_2)) +
        geom_point(aes(col = class, pch = class), cex = 2, 
                   alpha = 1 / 2) +
        geom_contour(
          data = grd, 
          aes(z = .pred_event),
          breaks = c(-Inf, 1 / 2, Inf),
          col = "black",
          linewidth = 1
        ) +

        # coord_equal() +
        theme(legend.position = "top") +
        lims(x = c(-1, 1), y = c(-1, 1)) +
        labs(x = "Predictor 1", y = "Predictor 2")
      
      p
      
    },
    height = 400, width = 400)
}

shinyApp(ui, server)
