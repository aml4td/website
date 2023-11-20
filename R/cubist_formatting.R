reformat_delivery_rules <- function(x) {
  x <- gsub("order_time", "time of order", x)
  x <- gsub("order_day", "day", x)
  x <- gsub(" %in%", "in", x)  
  x <- gsub("%in%", "in", x)
  x <- gsub("==", "is", x)  
  x <- gsub("c(", "(", x, fixed = TRUE)
  x <- strsplit(x, "&")
  x <- map(x, trimws)
  x <- map(x, ~ gsub("\\)$", "", .x))
  x <- map(x, ~ gsub("^\\(", "", .x))
  x <- map(x, trimws)
  x <- paste0(sort(x[[1]]), collapse = " AND ")
  x
}

reformat_delivery_eqn <- function(x) {
  p <- nrow(x)
  x$term <- gsub("(Intercept)", "", x$term, fixed = TRUE)
  x$term <- gsub("order_time", "(time of order)", x$term)
  x$term <- gsub("order_day", "day", x$term)
  
  any_prod <- grepl("^product", x$term)
  if (any(any_prod)) {
    prod_nums <- gsub("product_(.*?)", "\\1", x$term)
    prod_nums <- gsub("^0", "", prod_nums)
    prod_nums <- paste0("product_{", prod_nums, "}")
    x$term[which(any_prod)] <- prod_nums[which(any_prod)]
  }
  x$sign <- c(ifelse(sign(x$estimate[-1]) == 1, "+", " "), "")

  x$coef <- format(x$estimate, signif = 2)
  trm_len <- nchar(x$term)
  x$eq <- ifelse(trm_len > 0, paste(x$coef, x$term, x$sign), paste0(x$coef, " "))
  
  paste(x$eq, collapse = "")
}
