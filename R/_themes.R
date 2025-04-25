require(ggplot2)
require(gt)

# ------------------------------------------------------------------------------
# Themes for plots, tables, and shiny apps

light_bg <- "#fcfefe" # from aml4td.scss
dark_bg <- "#222222" 
dark_line <- "#adb5bd"
dark_data <- "#CCDEEC"
dark_gold <- "#E7D283"  
dark_tan <- "#F2EFE5"

# ------------------------------------------------------------------------------
# ggplot stuff

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

dk_text <- ggplot2::element_text(color = dark_line)
dk_rect <- ggplot2::element_rect(fill = "transparent", color = dark_line)

dk_thm <- 
  ggplot2::theme_dark() +
  ggplot2::theme(
    text = dk_text,
    panel.background = ggplot2::element_rect(fill = "transparent", color = dark_line),
    plot.background = ggplot2::element_rect(fill = "transparent", color = NA),
    strip.background = dk_rect,
    axis.text.x = ggplot2::element_text(colour = dark_data),
    axis.text.y = ggplot2::element_text(colour = dark_data),
    legend.position = "top", 
    legend.direction = "horizontal",
    legend.background = ggplot2::element_rect(fill = "transparent", color = dark_bg),
    legend.box.background = ggplot2::element_rect(fill = "transparent", color = dark_bg)
  )

dk_gif_thm <- 
  ggplot2::theme_dark() +
  ggplot2::theme(
    text = dk_text,
    panel.background = dk_rect,
    plot.background = ggplot2::element_rect(fill = dark_bg, color = NA),
    strip.background = dk_rect,
    axis.text.x = ggplot2::element_text(colour = dark_data),
    axis.text.y = ggplot2::element_text(colour = dark_data),
    legend.position = "top", 
    legend.direction = "horizontal",
    legend.background = ggplot2::element_rect(fill = "transparent", color = dark_bg),
    legend.box.background = ggplot2::element_rect(fill = "transparent", color = dark_bg)
  )

# ------------------------------------------------------------------------------

lt_tbl_thm <- function(gt_object, ...) {
  gt_object %>%
    gt::tab_options(
      table.background.color = light_bg,
      table.font.color.light = "grey",
      table.border.left.color = light_bg,
      table.border.right.color = light_bg,
      table_body.border.bottom.color = "grey",
      table_body.border.top.color = "grey",
      column_labels.background.color = light_bg,
      data_row.padding = gt::px(7),
      ...
    ) %>%
    gt::tab_style(
      style = gt::cell_text(
        color = "#595959",
        font = gt::google_font("Libre Franklin"),
      ),
      locations = gt::cells_column_labels()
    ) %>%
    gt::tab_style(
      style = gt::cell_text(
        color = "#595959",
        font = gt::google_font("Libre Franklin"),
      ),
      locations = gt::cells_body()
    ) %>%
    gt::tab_style(
      style = gt::cell_text(
        color = "#595959",
        font = gt::google_font("Libre Franklin"),
      ),
      locations = gt::cells_column_spanners()
    ) %>%
    gt::tab_style(
      style = gt::cell_text(
        font = gt::google_font("Libre Franklin"),
        weight = 800,
        color = "#595959"
      ),
      locations = gt::cells_title(groups = "title")
    ) |> 
    gt::tab_style(
      style = gt::cell_borders(sides = "bottom", weight = gt::px(3), col = "grey"),
      locations = list(
        gt::cells_column_labels()
      )
    )  |> 
    gt::tab_style(
      style = gt::cell_borders(
        sides = c("top", "bottom"),
        color = "grey",
        weight = gt::px(1),
        style = "solid"
      ),
      locations = gt::cells_body()
    )
}

dk_tbl_thm <- function(gt_object, ...) {
  gt_object %>%
    gt::tab_options(
      table_body.border.bottom.color = dark_tan,
      table_body.border.top.color = dark_tan,
      table.border.bottom.color = dark_tan,
      table.border.top.color = dark_tan,
      table.background.color = dark_bg,
      table.font.color.light = dark_tan,
      table.border.left.color = dark_bg,
      table.border.right.color = dark_bg,
      column_labels.background.color = dark_bg,
      data_row.padding = gt::px(7),
      ...
    ) %>%
    gt::tab_style(
      style = gt::cell_text(
        color = dark_line,
        font = gt::google_font("Libre Franklin"),
      ),
      locations = gt::cells_column_labels()
    ) %>%
    gt::tab_style(
      style = gt::cell_text(
        color = dark_line,
        font = gt::google_font("Libre Franklin"),
      ),
      locations = gt::cells_body()
    ) %>%
    gt::tab_style(
      style = gt::cell_text(
        color = dark_line,
        font = gt::google_font("Libre Franklin"),
      ),
      locations = gt::cells_column_spanners()
    ) %>%
    gt::tab_style(
      style = gt::cell_text(
        font = gt::google_font("Libre Franklin"),
        weight = 800,
        color = dark_line
      ),
      locations = gt::cells_title(groups = "title")
    ) |>
    gt::tab_style(
      style = gt::cell_borders(
        sides = c("top", "bottom"),
        weight = gt::px(3),
        col = dark_tan
      ),
      locations = list(
        gt::cells_column_labels(), 
        gt::cells_column_spanners()
      )
    ) |>
    gt::tab_style(
      style = gt::cell_borders(
        sides = c("top", "bottom"),
        color = dark_tan,
        weight = gt::px(1),
        style = "solid"
      ),
      locations = gt::cells_body()
    )
}

h2rgb <- function(x) {
  pct <- paste0(round(col2rgb(x)[,1] / 255 * 100, 1), "%") 
  pct <- paste0(pct, collapse = ", ")
  paste0("rgb(", pct, ")")
}
