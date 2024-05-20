light_bg <- "#fcfefe" # from aml4td.scss
grid_theme <- bs_theme(
  bg = "#fcfefe", fg = "#595959"
)

theme_light_bl<- function(...) {
  
  ret <- ggplot2::theme_bw(...)
  
  col_rect <- ggplot2::element_rect(fill = light_bg, colour = light_bg)
  ret$panel.background  <- col_rect
  ret$plot.background   <- col_rect
  ret$legend.background <- col_rect
  ret$legend.key        <- col_rect
  
  larger_x_text <- ggplot2::element_text(size = rel(1.25))
  larger_y_text <- ggplot2::element_text(size = rel(1.25), angle = 90)
  ret$axis.text.x <- larger_x_text
  ret$axis.text.y <- larger_y_text
  ret$axis.title.x <- larger_x_text
  ret$axis.title.y <- larger_y_text  
  
  ret$legend.position <- "top"
  
  ret
}

col_rect <- ggplot2::element_rect(fill = light_bg, colour = light_bg)

