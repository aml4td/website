hotel_rates <- hotel_rates %>% arrange(arrival_date)
hotel_rate_split <- initial_time_split(hotel_rates, prop = c(0.75))
hotel_rate_train <- training(hotel_rate_split)
hotel_rate_test  <- testing(hotel_rate_split)

hotel_rate_rs  <-
  sliding_period(
    hotel_rate_train,
    index = arrival_date,
    period = "week",
    lookback = Inf,
    complete = TRUE,
    assess_stop = 2,
    step = 2,
    skip = 15
  )

# To be more informative, we'll alter the ID column to be the first day of 
# the holdout set
holdout_date <- 
  map_chr(hotel_rate_rs$splits, ~ as.character(min(assessment(.x)$arrival_date)))
hotel_rate_rs$id <- holdout_date
