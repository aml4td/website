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
    column(width = 2),
    column(
      width = 5,
      sliderInput(
        inputId = "mixture",
        label = "Lasso Proportion (glmnet only)",
        min = 0.1,
        max = 1.0,
        value = 0.6,
        width = "100%",
        step = 0.1
      )
    ), 
    column(
      width = 5,
      sliderInput(
        inputId = "gamma",
        label = "Clipping Threshold (SCAD and MCP only)",
        min = 4,
        max = 16,
        value = 5,
        width = "100%",
        step = 1
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
  load(url(
    "https://raw.githubusercontent.com/aml4td/website/logistic-reg/RData/all_penalties.RData"
  ))

  output$plot <-
    renderPlot({
      dat <- all_penalties |> dplyr::filter(method == input$method)
      if (input$method == "glmnet") {
        dat <- dat |> dplyr::filter(mixture == input$mixture)
      } else if (input$method %in% c("SCAD", "MCP")) {
        dat <- dat |> dplyr::filter(gamma == input$gamma)
      }
        
      p <-
        dat |> 
        ggplot(aes(penalty, estimate, col = Term, pch = Term))  +
        geom_hline(yintercept = 0 , col = "red", linewidth = 1.1, alpha = 1 / 8) +
        geom_hline(data = mle_est, aes(yintercept = estimate, col = Term), 
                   lty = 2, alpha = 3 / 4) +
        geom_line(alpha = 1 / 2) +
        geom_point(alpha = 1 / 2) +
        scale_x_log10(labels = label_log()) +
        scale_color_manual(values = c("#3381A8FF", "#5E9546FF")) +
        labs(x = "Penalty", y = "Parameter Estimate") +
        theme_bw() +
        theme(legend.position = "top")
      
      print(p)
    }, 
    res = 120)
}

app <- shinyApp(ui = ui, server = server)

app
