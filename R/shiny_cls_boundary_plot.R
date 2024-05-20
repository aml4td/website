
plot_boundary <- function(pred, grid) {
  shiny_cls_cols <- c("#4151B0FF",  "#D0641EFF")
  
  grid$probability <- grid$.pred_event
  p <- 
    ggplot(pred, aes(predictor_1, predictor_2)) +
    geom_raster(
      data = grid, 
      aes(fill = probability),
      alpha = 1 / 4
    ) +
    geom_point(aes(col = class, pch = class), cex = 2, alpha = 3 / 4, show.legend = FALSE)
  
  # Example of only a single predicted probability; otherwise an error
  if ( sd(grid$.pred_event) >= 0.001 ) {
    p <- p + 
      geom_contour(
        data = grid, 
        aes(z = .pred_event),
        breaks = c(-Inf, 1 / 2, Inf),
        col = "black",
        linewidth = 1, 
        show.legend = FALSE
      )
  }
  
  p <- p +
    coord_equal() +
    scale_fill_gradient2(
      midpoint = 1 / 2,
      low = shiny_cls_cols[2],
      high = shiny_cls_cols[1],
      breaks = seq(0, 1, by = 0.25)
    ) +
    scale_color_manual(values = shiny_cls_cols) +
    theme(legend.position = "top") +
    labs(x = "Predictor 1", y = "Predictor 2") +
    theme_light_bl()
  
  p
}
