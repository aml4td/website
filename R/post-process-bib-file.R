library(purrr)
library(bibtex)
library(glue)

# ------------------------------------------------------------------------------

scholar_url <- function(title, year) {
  if (is.na(title) || nchar(title) < 5) {
    return(title)
  }
  if (grepl("href", title)) {
    return(title)
  }
  
  tags <- c("em", "it", "tt", "bf")

  for (pat in tags) {
    pattern <- glue::glue("\\{\\\\|pat| (.*?)\\}", .open = "|", .close = "|")
    title <- gsub(pattern, "\\1", title)
  }
  

  title <- gsub("[[:punct:]]", " ", title)
  title <- gsub("[[:space:]]+", " ", title)
  title <- gsub("[[:space:]]", "+", title)
  # default to english :-(
  glue::glue("https://scholar.google.com/scholar?hl=en&as_sdt=0%2C7&q={title}{year}&btnG=")
}


insert_link <- function(x, type) {
  if (type != "Article") {
    return(x)
  }
  yr <- x$year
  yr_txt <- character(0)
  if (!is.na(yr) && nchar(yr) >= 4) {
    yr <- substr(yr, 1, 4)
    yr_txt <- glue::glue("&as_ylo={yr}&as_yhi={yr}")
  }

  title <- x$title
  article_url <- scholar_url(title, yr_txt)
  href <- glue::glue("\\href{|article_url|}{|title|}", .open = "|", .close = "|")
  x$title <- href
  
  x
}

# ------------------------------------------------------------------------------

bib_items <- read.bib("includes/references_original.bib")
bib_dups <- bib_items[duplicated(bib_items)]
if (length(bib_dups) > 0) {
  dup_id <- names(bib_dups)
  cli::cli_abort("There are duplicate bib entries: {dup_id}")
}

bib_types <- map_chr(bib_items, ~ attr(.x, "bibtype"))
bib_year <- map_chr(bib_items, ~ .x$year)
bib_with_links <- map2(bib_items, bib_types, insert_link)
bib_with_links <- bib_with_links[order(bib_year)]
class(bib_with_links) <- class(bib_items)
write.bib(bib_with_links, file = "includes/references_linked.bib")
