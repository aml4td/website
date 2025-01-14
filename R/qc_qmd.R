# Code to find and maybe fix small issues with content:
# - section with not stub
# - titles but not in title case
# - no fancy quotes


# See this repo for a much more sophisticated and rigorour approach: 
# https://github.com/DavidAnson/markdownlint

get_title <- function(txt) {
  orig <- txt
  txt <- gsub("#", "", txt)
  txt <- strsplit(txt, split = "\\{")[[1]]
  if (length(txt) > 0) {
    txt <- txt[[1]]
  }
  txt <- trimws(txt)
  cln <- tools::toTitleCase(txt)
  fixed <- gsub(txt, cln, orig, fixed = TRUE)
  fixed
}

needs_stub <- function(txt) {
  is_section <- grepl("(^#{2}.+)[a-zA-z]", txt)
  has_stub <- grepl("{#sec-", txt, fixed = TRUE)
  un_num <- grepl("{.unnumbered}", txt, fixed = TRUE)
  nada <- grepl("{-}", txt, fixed = TRUE)
  !has_stub & !un_num & !nada
}

qc_qmd <- function(path) {
  suppressPackageStartupMessages(library(dplyr))
  
  content <- readLines(path)
  file_nm <- basename(path)

  # check apostrophes
  content <- gsub("(”)|(“)", "\"", content)
  
  # check data are plural
  # TODO

  # Section checks and fixes
  is_section <- grepl("(^#{2}.+) [a-zA-z]", content)
  ind_section <- which(is_section)
  for (i in ind_section) {
    ## is it title case?
    content[i] <- get_title(content[i])
    ## check that there is a stub for each section
    if (needs_stub(content[i])) {
      cli::cli_inform(c(x = "Needs a stub: {.val {content[i]}} at {.file {path}:{i}}"))
      content[i] <- paste(content[i], "{#sec-validation}")
    }
  }
  
  # mutiple blank lines
  blank_line <- grepl("^\\s*$", content)
  blank_line <- which(blank_line)
  blank_diff <- diff(blank_line)
  if (any(blank_diff == 1)) {
    cli::cli_inform("There are some replicate blank lines")
    blank_start <- blank_line[blank_diff == 1]
    removals <- integer(0)
    for (blank_i in blank_start) {
      cat(cli::rule(), "\n")
      cli::cli_inform(c(x = "Extra blank line at {.file {path}:{blank_i}}:"))
      cat(content[(blank_i-2):(blank_i+2)], sep = "\n")
      removals <- c(removals, blank_i)
      cat(cli::rule(), "\n")
    }
    removals <- unique(removals)
    content <- content[-removals]
  }
  
  # write out results
  cat(content, file = path, sep = "\n")
  invisible(TRUE)
}

qmd_files <- list.files(path = "chapters", pattern = "\\.qmd$", full.names = TRUE)
qmd_files <- qmd_files[!grepl("(news)|(contri)", qmd_files)]
linted <- purrr::map_lgl(qmd_files, qc_qmd)
