library(shiny)
library(ggplot2)
library(bslib)
library(viridis)


# ------------------------------------------------------------------------------

# load data

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
        inputId = "adjust_deg_free",
        label = "Adjsuted DF",
        min = 1,
        max = 2.5,
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
      
      grd <- grid_gam[grid_gam$adjust_deg_free == input$adjust_deg_free ,]
      
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
