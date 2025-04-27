require(ggplot2)
# source "_themes.R"

# ------------------------------------------------------------------------------

transparent_rect <- ggplot2::element_rect(fill = "transparent", colour = NA)
dk_text <- ggplot2::element_text(color = dark_line)
dk_rect <- ggplot2::element_rect(fill = "transparent", color = dark_line)

thm_transparent <- function(...) {
  
  ret <- ggplot2::theme_bw(...)
  
  transparent_rect <- ggplot2::element_rect(fill = "transparent", colour = NA)
  ret$panel.background  <- transparent_rect
  ret$plot.background   <- transparent_rect
  ret$legend.background <- transparent_rect
  ret$legend.key        <- transparent_rect
  
  ret$legend.position <- "top"
  
  ret
}

thm_lt <- 
  ggplot2::theme(
    panel.background = transparent_rect,
    plot.background = transparent_rect,
    legend.background = transparent_rect,
    legend.key  = transparent_rect,
    legend.position = "top", 
    legend.direction = "horizontal"
  )

thm_dk <- 
  ggplot2::theme_dark() +
  ggplot2::theme(
    text = dk_text,
    panel.background = dk_rect,
    plot.background = transparent_rect,
    strip.background = dk_rect,
    axis.text.x = ggplot2::element_text(colour = dark_data),
    axis.text.y = ggplot2::element_text(colour = dark_data),
    legend.position = "top", 
    legend.direction = "horizontal",
    legend.background = ggplot2::element_rect(fill = "transparent", color = NA),
    legend.box.background = ggplot2::element_rect(fill = "transparent", color = NA),
    legend.key = ggplot2::element_rect(fill = "transparent", colour = NA)
  )

dk_gif_thm <- 
  ggplot2::theme_dark() +
  ggplot2::theme(
    text = dk_text,
    panel.background = transparent_rect,
    plot.background = transparent_rect,
    strip.background = dk_rect,
    axis.text.x = ggplot2::element_text(colour = dark_data),
    axis.text.y = ggplot2::element_text(colour = dark_data),
    legend.position = "top", 
    legend.direction = "horizontal",
    legend.background = ggplot2::element_rect(fill = "transparent", color = dark_bg),
    legend.box.background = ggplot2::element_rect(fill = "transparent", color = dark_bg),
    legend.key = ggplot2::element_rect(fill = "transparent", colour = dark_bg)
  )
