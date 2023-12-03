hotel_rates <- hotel_rates %>% arrange(arrival_date)
hotel_rate_split <- initial_time_split(hotel_rates, prop = c(0.75))
hotel_rate_train <- training(hotel_rate_split)
hotel_rate_test  <- testing(hotel_rate_split)

set.seed(6858)
hotel_rate_rs  <- vfold_cv(hotel_rate_train, strata = avg_price_per_room)
