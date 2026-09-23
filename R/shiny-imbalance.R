
library(shiny)
library(bslib)
library(ggplot2)
library(dplyr)
library(scales)

source("https://raw.githubusercontent.com/aml4td/website/main/R/shiny-setup.R")

ui <- page_fillable(
  theme = bs_theme(bg = "#fcfefe", fg = "#595959"),
  padding = "1rem",
  layout_columns(
    fill = FALSE,
    col_widths = breakpoints(sm = c(-1, 10, -1)),
    column(
      width = 10,
      selectInput(
        inputId = "method",
        label = " ",
        choices = c(
          "Downsampled",
          "SMOTE",
          "ROSE",
          "Near Miss",
          "Tomek"
        ),
        selected = c("Downsampled")
      )
    )
  ),
  as_fill_carrier(plotOutput("plot")),
  br(),
  textOutput("text")
)

server <- function(input, output) {
  load("RData/imbalanced_sampled2.RData")
  
  xrng <- range(imbalanced_sampled$A)
  yrng <- range(imbalanced_sampled$B)
  
  orig <- imbalanced_sampled %>%
    dplyr::filter(Data == "Original")
  
  output$plot <-
    renderPlot(
      {
        dat <- imbalanced_sampled %>%
          dplyr::filter(Data == input$method) |>
          dplyr::bind_rows(orig) |>
          dplyr::mutate(
            Data = factor(Data, levels = c("Original", input$method))
          )
        
        grid <- imbalanced_grid %>%
          dplyr::filter(Data == input$method) |>
          dplyr::select(-Data) |>
          filter(!is.na(.pred_red))
        p <-
          dat |>
          ggplot(
            aes(A, B)
          ) +
          geom_point(
            aes(
              col = class
              # pch = class
            ),
            cex = 2,
            alpha = 1 / 3
          ) +
          facet_wrap(~Data) +
          coord_fixed(ratio = 1) +
          scale_x_continuous(limits = xrng, expand = c(0, 0)) +
          scale_y_continuous(limits = yrng, expand = c(0, 0))
        
        p <- p +
          theme(legend.position = "top") +
          scale_color_brewer(drop = FALSE, palette = "Set1") +
          theme_light_bl()
        
        p <-
          p +
          geom_tile(data = grid, aes(fill = .pred_red), alpha = .05) +
          geom_contour(
            data = grid,
            aes(z = .pred_red),
            breaks = 1 / 2,
            col = "black"
          ) +
          scale_fill_gradient2(
            low = "#377EB8",
            mid = "white",
            high = "#E41A1C",
            midpoint = 0.5
          ) +
          labs(
            x = "A",
            y = "B",
            fill = "Probability"
          )
        print(p)
      },
      res = 100
    )
  
  output$text <-
    renderText({
      paste0(
        "Using the default 50% threshold, this method correctly identified ", 
        imbalanced_hits[[input$method]][1], 
        " truly red points (out of ", 
        imbalanced_hits[[input$method]][2],
        ").") 
    })
}

app <- shinyApp(ui = ui, server = server)
app