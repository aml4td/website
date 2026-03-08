ui <- page_fillable(
  theme = bs_theme(bg = "#fcfefe", fg = "#595959"),
  padding = "1rem",
  layout_columns(
    fill = TRUE,
    column(
      width = 10,
      radioButtons(
        inputId = "method",
        label = "Method",
        choices = c(
          "Gini Index",
          "Information Gain",
          "Gain Ratio",
          "Chi-Square",
          "XGBoost",
          "LightGBM",
          "CatBoost"
        ),
        inline = TRUE
      )
    )
  ),

  as_fill_carrier(plotOutput("scores"))
)

server <- function(input, output) {
  # load(url(
  #   "https://raw.githubusercontent.com/aml4td/website/main/RData/barley_linear_embeddings.RData"
  # ))

  output$scores <-
    renderPlot(
      {
        chosen <-
          forested_split_examples %>%
          dplyr::filter(metric == input$method)

        if (input$method == "Gini Index") {
          best <-
            chosen |>
            slice_min(value)
        } else {
          best <-
            chosen |>
            slice_max(value)
        }

        others <-
          forested_split_examples %>%
          dplyr::filter(metric != input$method)

        p <-
          others %>%
          ggplot(aes(split_value)) +
          geom_line(
            aes(y = unit_value, group = metric),
            col = "black",
            alpha = 0.1,
            show.legend = FALSE
          ) +
          geom_line(data = chosen, aes(y = unit_value), col = "blue") +
          geom_rug(
            data = chosen,
            aes(x = split_value),
            col = "blue",
            alpha = 0.1
          ) +
          geom_vline(xintercept = best$split_value, lty = 2) +
          labs(x = "Maximum Vapor", y = "Normalized Statistic") +
          theme_light_bl()

        print(p)
      },
      res = 100
    )
}

app <- shinyApp(ui = ui, server = server)
