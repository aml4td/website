data(deliveries, package = "modeldata")

set.seed(991)
delivery_split <- initial_validation_split(deliveries, prop = c(0.6, 0.2), strata = time_to_delivery)
delivery_train <- training(delivery_split)
delivery_test  <- testing(delivery_split)
delivery_val   <- validation(delivery_split)
delivery_rs    <- validation_set(delivery_split)

## Some functions to faciltate the content

dec_to_time <- function(x) {
  mins <- floor(x)
  dec <- floor((x - mins) * 60)
  res <- cli::pluralize("{mins} minutes{?s} and {dec} second{?s}")
  res <- as.character(res)
  res <- gsub(" and 0 seconds", "", res)
  res <- gsub("1 minutes", "1 minute", res) 
  res
}

dec_to_time_rs <- function(x) {
  collect_metrics(x) %>% 
    filter(.metric == "mae") %>% 
    pluck("mean") %>% 
    dec_to_time
}

