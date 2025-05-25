# ------------------------------------------------------------------------------
# Commonly used colors

light_bg <-  "#fcfefe" 
dark_bg <-   "#222222" 
dark_line <- "#adb5bd"
dark_data <- "#CCDEEC"
dark_gold <- "#E7D283"  
dark_tan <-  "#F2EFE5"

# ------------------------------------------------------------------------------
# A helper for postprocessing svg files

h2rgb <- function(x) {
  pct <- paste0(round(col2rgb(x)[,1] / 255 * 100, 1), "%") 
  pct <- paste0(pct, collapse = ", ")
  paste0("rgb(", pct, ")")
}
