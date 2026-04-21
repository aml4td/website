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
