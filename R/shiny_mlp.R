library(shiny)
library(ggplot2)
library(bslib)
library(viridis)


# ------------------------------------------------------------------------------

load("/Users/max/content/website/RData/demo_data.RData")
load("/Users/max/content/website/RData/demo_grid.RData")
load("/Users/max/content/website/RData/grid_mlp.RData")

set.seed(986)
split <- initial_split(demo_data, prop = 2 / 3, strata = class)
demo_tr <- training(split)
demo_te <- testing(split)
rngs <- list(x = range(demo_data$predictor_1), y = range(demo_data$predictor_2))



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
        inputId = "hidden_units",
        label = "Hidden units",
        min = 3,
        max = 30,
        value = 6,
        width = "100%",
        step = 3
      )
    ), # hidden_units
    
    column(
      width = 6,
      sliderInput(
        inputId = "penalty",
        label = HTML("Weight Decay (log<sub>10</sub>)"),
        min = -5,
        max = -1,
        value = -2,
        width = "100%",
        step = 1
      )
    ),
    fluidRow(
      column(
        width = 4,
        radioButtons(
          inputId = "activation",
          label = "Activation",
          choices = list("tanh", "relu", "sigmoid", "celu")
        ),
        radioButtons(
          inputId = "stop_iter",
          label = "Early Stopping?",
          choices = list("Yes" = "yes", "No" = "no"),
          selected = "yes"
        ),
        radioButtons(
          inputId = "data_set",
          label = "Show Data",
          choices = list("Training" = "training", "Testing" = "testing"),
          selected = "testing"
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

      stop_iter <- ifelse(input$stop_iter == "yes", 5, max(grid_mlp$stop_iter))
      grd <- 
        grid_mlp[
          grid_mlp$penalty == input$penalty & 
            grid_mlp$activation == input$activation & 
            grid_mlp$hidden_units == input$hidden_units & 
            grid_mlp$stop_iter == stop_iter,]
      
      if (input$data_set == "testing") {
        plot_data <- demo_te
      } else {
        plot_data <- demo_tr
      }
      
      p <- 
        ggplot(plot_data, aes(predictor_1, predictor_2)) +
        geom_point(aes(col = class, pch = class), cex = 2, 
                   alpha = 1 / 2) +
        geom_contour(
          data = grd, 
          aes(z = .pred_A),
          breaks = c(-Inf, 1 / 2, Inf),
          col = "black",
          linewidth = 1
        ) +

        # coord_equal() +
        theme(legend.position = "top") +
        lims(x = rngs$x, y = rngs$y) +
        labs(x = "Predictor 1", y = "Predictor 2")
      
      p
      
    },
    height = 400, width = 400)
}

shinyApp(ui, server)
