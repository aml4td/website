# ------------------------------------------------------------------------------

# This determines if RData files are saved at the end of the qmd files. The
# teardown can often take a while and will produce a lot of RData files that
# may take time to commit.

# During content/code development, a value of FALSE is good when the saved results
# are not changing.
teardown <- TRUE

# ------------------------------------------------------------------------------

light_bg <- "#fcfefe" # from aml4td.scss

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



