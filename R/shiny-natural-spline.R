data(fossil)

ui <- page_fillable(
  theme = bs_theme(),
  bslib::input_dark_mode(),
  padding = "1rem",
  layout_columns(
    fill = FALSE,
    col_widths = breakpoints(sm = c(-3, 6, -3)),
    sliderInput(
      "spline_df",
      label = "# Spline Terms",
      min = 3L, max = 20L, step = 1L, value = 9L
    ), # sliderInput
  ), # layout_columns
  layout_columns(
    fill = FALSE,
    col_widths = breakpoints(sm = c(-1, 10, -1)),
    as_fill_carrier(plotOutput('spline'))
  )         
)

server <- function(input, output, session) {
  
  theme_set(theme_transparent())
  transparent_rect <- ggplot2::element_rect(fill = "transparent", colour = NA)
  
  # ------------------------------------------------------------------------------

  maybe_lm <- function(x) {
    try(lm(y ~ poly(x, input$piecewise_deg), data = x), silent = TRUE)
  }
  
  expansion_to_tibble <- function(x, original, prefix = "term ") {
    cls <- class(x)[1]
    nms <- recipes::names0(ncol(x), prefix)
    colnames(x) <- nms
    x <- as_tibble(x)
    x$variable <- original
    res <- tidyr::pivot_longer(x, cols = c(-variable))
    if (cls != "poly") {
      res <- res[res$value > .Machine$double.eps,]
    }
    res
  } 
  
  mult_poly <- function(dat, degree = 4) {
    rng <- extendrange(dat$x, f = .025)
    grid <- seq(rng[1], rng[2], length.out = 1000)
    grid_df <- tibble(x = grid)
    feat <- poly(grid_df$x, degree)
    res <- expansion_to_tibble(feat, grid_df$x)
    
    # make some random names so that we can plot the features with distinct colors
    rand_names <- lapply(1:degree, function(x) paste0(sample(letters)[1:10], collapse = ""))
    rand_names<- unlist(rand_names)
    rand_names <- tibble(name = unique(res$name), name2 = rand_names)
    res <- 
      dplyr::inner_join(res, rand_names, by = dplyr::join_by(name)) %>% 
      dplyr::select(-name) %>% 
      dplyr::rename(name = name2)
    res
  }
  
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
  
  output$spline <- renderPlot({
    
    spline_fit <- lm(y ~ naturalSpline(x, df = input$spline_df), data = spline_example)
    spline_pred <- 
      predict(spline_fit, grid_df, interval = "confidence", level = .90) %>% 
      bind_cols(grid_df)
    
    spline_p <- base_p +
      geom_ribbon(
        data = spline_pred,
        aes(y = NULL, ymin = lwr, ymax = upr),
        alpha = 1 / 15) +
      geom_line(
        data = spline_pred,
        aes(y = fit),
        col = "black",
        linewidth = line_wd)
    
    feature_p <-
      naturalSpline(grid_df$x, df = input$spline_df) %>% 
      expansion_to_tibble(grid_df$x) %>% 
      ggplot(aes(variable, y = value, group = name, col = name)) +
      geom_line(show.legend = FALSE) + 
      lims(x = rng) +
      theme_void() +
      theme(
        plot.margin = margin(t = 0, r = 0, b = -20, l = 0),
        panel.background = transparent_rect,
        plot.background = transparent_rect,
        legend.background = transparent_rect,
        legend.key = transparent_rect
      ) +
      scale_color_viridis(discrete = TRUE, option = "turbo")
    
    p <- (feature_p / spline_p) + plot_layout(heights = c(1, 4))
    
    print(p)
    
  })
  
}

app <- shinyApp(ui = ui, server = server)
