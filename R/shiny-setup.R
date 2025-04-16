light_bg <- "#fcfefe" # from aml4td.scss
grid_theme <- bs_theme(
	bg = light_bg,
	fg = "#595959"
)

col_rect <- ggplot2::element_rect(fill = light_bg, colour = light_bg)

theme_light_bl <- function(...) {
	ret <- ggplot2::theme_bw(...)

	ret$panel.background <- col_rect
	ret$plot.background <- col_rect
	ret$legend.background <- col_rect
	ret$legend.key <- col_rect

	ret$legend.position <- "top"

	ret
}

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
