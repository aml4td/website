plot_boundary <- function(pred, grid) {
  shiny_cls_cols <- c("#4151B0FF",  "#D0641EFF")
  
  ggplot(pred, aes(predictor_1, predictor_2)) +
    geom_raster(
      data = grid, 
      aes(fill = .pred_class),
      alpha = 1 / 20, 
      show.legend = FALSE
    ) +
    geom_point(aes(col = class, pch = class), cex = 2, alpha = 3 / 4) +        
    geom_contour(
      data = grid, 
      aes(z = .pred_event),
      breaks = c(-Inf, 1 / 2, Inf),
      col = "black",
      linewidth = 1, 
      show.legend = FALSE
    ) +
    coord_equal() +
    # theme_light_bl() +
    scale_fill_manual(values = shiny_cls_cols) +
    scale_color_manual(values = shiny_cls_cols) +
    theme(legend.position = "top") +
    labs(x = "Predictor 1", y = "Predictor 2")
}
