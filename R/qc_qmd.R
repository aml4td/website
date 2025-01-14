# Code to find and maybe fix small issues with content:
# - section with not stub
# - titles but not in title case
# - no fancy quotes

# md linters can flag a lot more, such as
# https://github.com/DavidAnson/markdownlint/tree/v0.37.3

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

# get_title("### Overall Comparisons")
# get_title("## Linear Transformations  {#sec-linear-embed}")
# get_title("#### How to incorporate PCA into the model {.unnumbered}")

needs_stub <- function(txt) {
  is_section <- grepl("(^#{2}.+)[a-zA-z]", txt)
  has_stub <- grepl("{#sec-", txt, fixed = TRUE)
  un_num <- grepl("{.unnumbered}", txt, fixed = TRUE)
  nada <- grepl("{-}", txt, fixed = TRUE)
  !has_stub & !un_num & !nada
}

qc_qmd <- function(path) {
  content <- readLines(path)
  cli::cli_inform(c(i = "processing {.val {basename(path)}}"))
  # check apostrophies
  content <- gsub("(”)|(“)", "\"", content)
  
  # check data are plural
  
  # mutiple blank lines

  # Section checks and fixes
  is_section <- grepl("(^#{2}.+) [a-zA-z]", content)
  ind_section <- which(is_section)
  for (i in ind_section) {
    ## is it title case?
    content[i] <- get_title(content[i])
    ## check that there is a stub for each section
    if (needs_stub(content[i])) {
      cli::cli_inform(c(x = "Line {i} needs a stub: {.val {content[i]}}"))
    }
  }
  
  # write out results
  cat(content, file = path, sep = "\n")
  invisible(TRUE)
}

qmd_files <- list.files(path = "chapters", pattern = "\\.qmd$", full.names = TRUE)
qmd_files <- qmd_files[!grepl("(news)|(contri)", qmd_files)]
linted <- purrr::map_lgl(qmd_files, qc_qmd)


