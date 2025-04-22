# ------------------------------------------------------------------------------

# This determines if RData files are saved at the end of the qmd files. The
# teardown can often take a while and will produce a lot of RData files that
# may take time to commit.

# During content/code development, a value of FALSE is good when the saved results
# are not changing.
teardown <- TRUE

# ------------------------------------------------------------------------------

light_bg <- "#fcfefe" # from aml4td.scss
dark_bg <- "#222" 

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

log_2_breaks <- scales::trans_breaks("log2", function(x) 2^x)
log_2_labs   <- scales::trans_format("log2", scales::math_format(2^.x))

dk_text <- ggplot2::element_text(color = "#adb5bd")
dk_rect <- ggplot2::element_rect(fill = "transparent", color = "#adb5bd")

dk_thm <- 
  ggplot2::theme_dark() +
  ggplot2::theme(
    text = dk_text,
    legend.background = dk_rect,
    legend.box.background = dk_rect,
    panel.background = dk_rect,
    plot.background = ggplot2::element_rect(fill = "transparent", color = NA),
    strip.background = dk_rect,
    axis.text.x = ggplot2::element_text(colour = "#CCDEEC"),
    axis.text.y = ggplot2::element_text(colour = "#CCDEEC")
  )

dk_gif_thm <- 
  ggplot2::theme_dark() +
  ggplot2::theme(
    text = dk_text,
    legend.background = dk_rect,
    legend.box.background = dk_rect,
    panel.background = dk_rect,
    plot.background = ggplot2::element_rect(fill = "#222", color = NA),
    strip.background = dk_rect,
    axis.text.x = ggplot2::element_text(colour = "#CCDEEC"),
    axis.text.y = ggplot2::element_text(colour = "#CCDEEC")
  )

# ------------------------------------------------------------------------------

lt_tbl_thm <- function(gt_object, ...) {
  gt_object %>%
    gt::tab_options(
      table.background.color = "#fcfefe",
      table.font.color.light = "grey",
      table.border.left.color = "#fcfefe",
      table.border.right.color = "#fcfefe",
      table_body.border.bottom.color = "grey",
      table_body.border.top.color = "grey",
      column_labels.background.color = "#fcfefe",
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
      table_body.border.bottom.color = "#F2EFE5",
      table_body.border.top.color = "#F2EFE5",
      table.border.bottom.color = "#F2EFE5",
      table.border.top.color = "#F2EFE5",
      table.background.color = "#222",
      table.font.color.light = "#F2EFE5",
      table.border.left.color = "#222",
      table.border.right.color = "#222",
      column_labels.background.color = "#222",
      data_row.padding = gt::px(7),
      ...
    ) %>%
    gt::tab_style(
      style = gt::cell_text(
        color = "#adb5bd",
        font = gt::google_font("Libre Franklin"),
      ),
      locations = gt::cells_column_labels()
    ) %>%
    gt::tab_style(
      style = gt::cell_text(
        color = "#adb5bd",
        font = gt::google_font("Libre Franklin"),
      ),
      locations = gt::cells_body()
    ) %>%
    gt::tab_style(
      style = gt::cell_text(
        color = "#adb5bd",
        font = gt::google_font("Libre Franklin"),
      ),
      locations = gt::cells_column_spanners()
    ) %>%
    gt::tab_style(
      style = gt::cell_text(
        font = gt::google_font("Libre Franklin"),
        weight = 800,
        color = "#adb5bd"
      ),
      locations = gt::cells_title(groups = "title")
    ) |>
    gt::tab_style(
      style = gt::cell_borders(
        sides = c("top", "bottom"),
        weight = gt::px(3),
        col = "#F2EFE5"
      ),
      locations = list(
        gt::cells_column_labels(), 
        gt::cells_column_spanners()
      )
    ) |>
    gt::tab_style(
      style = gt::cell_borders(
        sides = c("top", "bottom"),
        color = "#F2EFE5",
        weight = gt::px(1),
        style = "solid"
      ),
      locations = gt::cells_body()
    )
}

# ------------------------------------------------------------------------------
# formatting for package names

pkg <- function(x) {
  cl <- match.call()
  x <- as.character(cl$x)
  paste0('<span class="pkg">', x, '</span>')
}

pkg_chr <- function(x) {
  paste0('<span class="pkg">', x, '</span>')
}

# ------------------------------------------------------------------------------

holdout_plots <- function(x, resid_rng, alpha = 3/4) {
  require(patchwork)

  y_nm <- .get_tune_outcome_names(x)
  met <- .get_tune_metric_names(x)[1]

  tuned <- length(.get_tune_parameter_names(x)) > 0
  if (tuned) {
    bst <- select_best(x, metric = met)
    preds <- collect_predictions(x, parameters = bst, summarize = TRUE)
  } else {
    preds <- collect_predictions(x, summarize = TRUE)
  }

  preds <-
    preds %>%
    mutate(.resid = !!sym(y_nm) - .pred)

  o_v_p <-
    preds %>%
    ggplot(aes(.pred, y = !!sym(y_nm))) +
    geom_abline(col = "green", lty = 2) +
    geom_point(alpha = alpha) +
    coord_obs_pred() +
    labs(x = "Predicted")

  r_v_p <-
    preds %>%
    ggplot(aes(.pred, y = .resid)) +
    geom_hline(col = "green", lty = 2, yintercept = 0) +
    geom_point(alpha = alpha) +
    labs(x = "Predicted", y = "Residual") +
    lims(y = resid_rng)
  o_v_p + r_v_p
}

# ------------------------------------------------------------------------------

val_roc_plots <- function(x) {
  new_nm <- x$Model[1]
  new_res <- dplyr::filter(x, Model == new_nm)
  prev_res <- dplyr::filter(x, Model != new_nm)

  x %>%
    ggplot(aes(x = 1 - specificity, y = sensitivity)) +
    geom_abline(col = "red", lty = 3) +
    geom_step(data = prev_res, aes(group = Model), show.legend = FALSE, col = "blue", alpha = 0.2) +
    geom_step(data = new_res, col = "black") +
    coord_obs_pred()
}

val_roc_curves <- function(x, prev = NULL) {
  x_nm <- match.call()$x
  x_nm <- as.character(x_nm)
  res <-
    x %>%
    collect_predictions(parameters = select_best(x, metric = "roc_auc")) %>%
    roc_curve(truth = on_goal, .pred_yes) %>%
    mutate(Model = x_nm)
  if (!is.null(prev)) {
    res <- bind_rows(res, prev)
  }
  res
}

is_m1_mac <- Sys.info()["machine"] == "arm64"

# ------------------------------------------------------------------------------
# Try to avoid repetition when saving

save_new_version <- function(x, pth, verbose) {
  if (!file.exists(pth)) {
    return(TRUE)
  }
  load(pth)
  obj_name <- basename(pth)
  obj_name <- gsub(".RData", "", obj_name, fixed = TRUE)
  diffs <-
    waldo::compare(
      get(obj_name),
      x,
      ignore_srcref = TRUE,
      ignore_function_env = TRUE,
      ignore_formula_env = TRUE
    )
  if (verbose) {
    cat(cli::rule(obj_name), "\n")
    print(diffs)
  }
  length(diffs) > 0
}

save_obj <- function(x, verbose = FALSE) {
  cl <- match.call()
  nm <- as.character(cl$x)
  assign(nm, x)
  file_nm <- glue::glue("../RData/{nm}.RData")

  # are there differences?
  should_save <- try(save_new_version(x, file_nm, verbose), silent = TRUE)
  if (inherits(should_save, "try-error")) {
    should_save <- TRUE
  }
  if (should_save) {
    save(
      list = nm,
      file = file_nm,
      version = 3,
      compress = TRUE,
      compression_level = 9
    )
  }
  invisible(file.exists(nm))
}

export_resamples <- function(x, label = NULL) {
  if (inherits(x, "tune_results")) {
    cl <- match.call()
    res <-
      list(
        x = collect_metrics(x, summarize = FALSE) %>%
          dplyr::mutate(model = label)
      )
    names(res) <- label
  } else {
    labs <- x$wflow_id
    res <-
      purrr::map(x$result, collect_metrics, summarize = FALSE) %>%
      purrr::map2(labs, ~ .x %>% dplyr::mutate(model = .y))
    names(res) <- labs
  }
  res
}

# ------------------------------------------------------------------------------
# Misc options for chunks and printing

set_options <- function() {
  options(digits = 4, width = 84)
  options(dplyr.print_min = 6, dplyr.print_max = 6)
  options(cli.width = 85)
  options(crayon.enabled = FALSE)
  options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
  invisible(NULL)
}

# ------------------------------------------------------------------------------
# triggers for target format and architecture

is_html <- knitr::is_html_output()
is_tex <- knitr::is_latex_output()
is_m1_mac <- Sys.info()["machine"] == "arm64"

# ------------------------------------------------------------------------------
# Differentially set the graphics device depending on the target format

if (is_html) {
  knitr::opts_chunk$set(
    comment = "#>",
    collapse = TRUE,
    fig.align = 'center',
    fig.path = "../figures/",
    fig.width = 10,
    fig.height = 6,
    out.width = "95%",
    dev = 'svg',
    dev.args = list(bg = "transparent"),
    tidy = FALSE,
    echo = FALSE
  )
} else {
  knitr::opts_chunk$set(
    comment = "#>",
    collapse = TRUE,
    fig.align = 'center',
    fig.path = "../figures/",
    fig.width = 10,
    fig.height = 6,
    out.width = "95%",
    dev = "pdf",
    tidy = FALSE,
    echo = FALSE
  )
}

# ------------------------------------------------------------------------------

lightsvglite <- function(file, width, height, ...) {
  on.exit(ggplot2::reset_theme_settings())
  
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
  
  ggplot2::theme_set(theme_transparent())
  ggsave(
    filename = file, #fs::path("figures", file),
    width = width,
    height = height,
    dev = "svg",
    bg = "transparent",
    ...
  )
}

darksvglite <- function(file, width, height, ...) {
  on.exit(ggplot2::reset_theme_settings())
  ggplot2::theme_set(ggdark::dark_theme_grey())
  ggsave(
    filename = file, #fs::path("figures", file),
    width = width,
    height = height,
    dev = "svg",
    bg = "transparent",
    ...
  )
}

r_comp <- function(stub) {
  glue::glue(
    '<a href="https://tidymodels.aml4td.org/chapters/[stub]">{{< fa brands r-project size=Large >}}</a>',
    .open = "[", .close = "]"
  )
}

# ------------------------------------------------------------------------------
# formatting data

pval <- function(x, format = "html", max_zeros = 4) {
  if (is.na(x)) {
    return("")
  }

  min_log <- floor(-log10(x))
  if (min_log < max_zeros) {
    res <- format(x, digits = 3, scientific = FALSE)
  } else {
    if (format == "plain") {
      res <- paste0("<10^-", min_log)
    } else if (format == "html") {
      res <- paste0("< 10<sup>-", min_log, "</sup>")
    } else {
      res <- paste0("$<10^{-", min_log, "}$")
    }
  }
  res
}

# ------------------------------------------------------------------------------
# From recipes::names0 and used in shinylive chunks; see https://github.com/aml4td/website/pull/80

names_zero_padded <- function(num, prefix = "x", call = rlang::caller_env()) {
  rlang:::check_number_whole(num, min = 1, call = call)
  ind <- format(seq_len(num))
  ind <- gsub(" ", "0", ind)
  paste0(prefix, ind)
}
