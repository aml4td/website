
data(fossil)

ui <- page_fillable(
  theme = bs_theme(),
  bslib::input_dark_mode(),
  padding = "1rem",
  layout_columns(
    fill = FALSE,
    col_widths = breakpoints(sm = c(-2, 8, -2)),
    sliderInput(
      "cuts",
      label = "Cutpoints",
      min = 93L, max = 122L, step = 1, value = c(107, 114)
    ) # sliderInput
  ), # layout_columns
  layout_columns(
    fill = FALSE,
    col_widths = breakpoints(sm = c(-1, 10, -1)),
    as_fill_carrier(plotOutput('splime_spline'))
  )      
)

server <- function(input, output, session) {
  
  theme_transparent <- function(...) {
    
    ret <- ggplot2::theme_bw(...)
    
    transparent_rect <- ggplot2::element_rect(fill = "transparent", colour = NA)
    ret$panel.background  <- transparent_rect
    ret$plot.background   <- transparent_rect
    ret$legend.background <- transparent_rect
    ret$legend.key        <- transparent_rect
    
    ret$legend.position <- "top"
    
    ret
  }
  
  theme_set(theme_transparent())
  transparent_rect <- ggplot2::element_rect(fill = "transparent", colour = NA)
  
  # ------------------------------------------------------------------------------

  spline_example <- tibble(x = fossil$age, y = fossil$strontium.ratio)
  rng <- extendrange(fossil$age, f = .025)
  grid <- seq(rng[1], rng[2], length.out = 1000)
  grid_df <- tibble(x = grid)
  alphas <- 1 / 4
  line_wd <- 1.0
  
  base_p <-
    spline_example %>%
    ggplot(aes(x = x, y = y)) +
    geom_point(alpha = 3 / 4, pch = 1, cex = 3) +
    labs(x = "Age", y = "Isotope Ratio") 
  
  output$splime_spline <- renderPlot({
    
    spline_p <- base_p
    
    h <- function(x) {
      ifelse(x > 0, x, 0)
    }
    
    mod_dat <- 
      spline_example %>% 
      mutate(
        x_2 = x^2, 
        x_3 = x^3,
        x_k_1 = pmax(h(x-min(input$cuts))^3, 0),
        x_k_2 = pmax(h(x-max(input$cuts))^3, 0)
      )
    
    grid_spln <- 
      grid_df %>% 
      mutate(
        x_2 = x^2, 
        x_3 = x^3,
        x_k_1 = pmax(h(x-min(input$cuts))^3, 0),
        x_k_2 = pmax(h(x-max(input$cuts))^3, 0)
      )
    
    features <- 
      rbind(
        tibble::tibble(x = grid_spln$x, value = grid_spln$x_k_1, term = "4") %>% 
          filter(value != 0),
        tibble::tibble(x = grid_spln$x, value = grid_spln$x_k_2, term = "5") %>% 
          filter(value != 0)
      )
    
    fit_1 <- lm(y ~ ., data = mod_dat)
    spline_pred <- 
      predict(fit_1, grid_spln, interval = "confidence", level = .90) %>% 
      bind_cols(grid_df)
    
    spline_p <-
      spline_p +
      geom_ribbon(
        data = spline_pred,
        aes(y = NULL, ymin = lwr, ymax = upr),
        fill = "#FBE577",
        alpha = 1 / 2
      ) +
      geom_line(
        data = spline_pred,
        aes(y = fit),
        col = "#FFBA18",
        linewidth = line_wd
      ) +
      geom_vline(xintercept = min(input$cuts), col = "#A6CEE3", lty = 2, linewidth = 1) +
      geom_vline(xintercept = max(input$cuts), col = "#1F78B4", lty = 2, linewidth = 1)
    
    term_p <- 
      features %>% 
      ggplot(aes(x, value, col = term)) +
      geom_line(show.legend = FALSE, linewidth = 1) +
      lims(x = rng) +
      theme_void() +
      theme(
        plot.margin = margin(t = 0, r = 0, b = -20, l = 0),
        panel.background = transparent_rect,
        plot.background = transparent_rect,
        legend.background = transparent_rect,
        legend.key = transparent_rect
      ) +
      scale_color_brewer(palette = "Paired")
    
    p <- (term_p / spline_p) + plot_layout(heights = c(1, 4))
    
    print(p)
    
  })
}

thematic_shiny()

app <- shinyApp(ui = ui, server = server)
