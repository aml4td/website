# source("https://raw.githubusercontent.com/aml4td/website/main/R/_themes.R")
# source("https://raw.githubusercontent.com/aml4td/website/main/R/_themes_ggplot.R")

# ------------------------------------------------------------------------------
# From recipes::names0 and used in shinylive chunks; see https://github.com/aml4td/website/pull/80

names_zero_padded <- function(num, prefix = "x", call = rlang::caller_env()) {
	rlang:::check_number_whole(num, min = 1, call = call)
	ind <- format(seq_len(num))
	ind <- gsub(" ", "0", ind)
	paste0(prefix, ind)
}


# ------------------------------------------------------------------------------
# for short url refs

rd_url <- function(nm) {
  rd_base <- "https://raw.githubusercontent.com/aml4td/website/main/RData"
  url(file.path(rd_base, nm))
}

# ------------------------------------------------------------------------------
# switch between light and dark themes

get_theme <- function(
    input,
    # these values found in _themes.R
    light = thm_lt,
    dark = thm_dk,
    # these values found in _themes_ggplot.R
    lt_bg = light_bg,
    dk_bg = dark_bg
) {
  if (input$mode == "light") {
    res <-
      light +
      theme(plot.background = element_rect(fill = lt_bg, color = lt_bg))
  } else {
    res <-
      dark +
      theme(plot.background = element_rect(fill = dk_bg, color = dk_bg))
  }
  res
}

