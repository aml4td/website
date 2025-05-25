require(gt)
source("https://raw.githubusercontent.com/aml4td/website/main/R/_themes.R")

# ------------------------------------------------------------------------------

thm_tbl_lt <- function(gt_object, ...) {
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

thm_tbl_dk <- function(gt_object, ...) {
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
