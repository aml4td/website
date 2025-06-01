library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)
library(scales)

light_bg <- "#fcfefe" # from aml4td.scss
grid_theme <- bs_theme(
  bg = light_bg,
  fg = "#595959"
)

theme_light_bl <- function(...) {
  ret <- ggplot2::theme_bw(...)
  
  col_rect <- ggplot2::element_rect(fill = light_bg, colour = light_bg)
  ret$panel.background <- col_rect
  ret$plot.background <- col_rect
  ret$legend.background <- col_rect
  ret$legend.key <- col_rect
  
  ret$legend.position <- "top"
  
  ret
}


ui <- fluidPage(
  theme = grid_theme,
  fluidRow(
    column(
      width = 6,
      sliderInput(
        inputId = "mixture",
        label = "Lasso Proportion (glmnet only)",
        min = 0.1,
        max = 0.9,
        value = 0.6,
        width = "100%",
        step = 0.1
      )
    ), # min distance
    column(
      width = 6,
      sliderInput(
        inputId = "gamma",
        label = "Clipping Threshold (SCAD and MCP only)",
        min = 4,
        max = 40,
        value = 20,
        width = "100%",
        step = 4
      )
    ), 
    
    fluidRow(
      column(
        width = 3,
        align = "left",
        radioButtons(
          inputId = "method",
          label = "Method",
          choices = list(
            "Ridge" = "Ridge",
            "Lasso" = "Lasso",
            "glmnet" = "glmnet",
            "SCAD" = "SCAD",
            "MCP" = "MCP"
          )
        )
      ),
      column(
        width = 9,
        align = "center",
        plotOutput('plot')
      )
    )
  ) # top fluid row
)

server <- function(input, output) {
  load("RData/all_penalties.RData")
  
  output$plot <-
    renderPlot({
      # browser()
      dat <- all_penalties |> dplyr::filter(method == input$method)
      if (input$method == "glmnet") {
        dat <- dat |> dplyr::filter(mixture == input$mixture)
      } else if (input$method %in% c("SCAD", "MCP")) {
        dat <- dat |> dplyr::filter(gamma == input$gamma)
      }
        
      p <-
        dat |> 
        ggplot(aes(penalty, estimate, col = Term, pch = Term))  +
        geom_hline(data = mle_est, aes(yintercept = estimate, col = Term), 
                   lty = 2, alpha = 3 / 4) +
        geom_line(alpha = 1 / 2) +
        geom_point(alpha = 1 / 2) +
        scale_x_log10(labels = label_log()) +
        scale_color_brewer(palette = "Dark2") +
        labs(x = "Penalty", y = "Parameter Estimate") +
        theme_bw() +
        theme(legend.position = "top")
      
      print(p)
    }, 
    res = 120)
}

app <- shinyApp(ui = ui, server = server)

app
