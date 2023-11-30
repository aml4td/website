
hotel_rate_split <- initial_validation_time_split(hotel_rates, prop = c(0.7, 0.15))
hotel_rate_train <- training(hotel_rate_split)
hotel_rate_val   <- testing(hotel_rate_split)
hotel_rate_test  <- validation(hotel_rate_split)

set.seed(6858)
hotel_rate_rs  <- validation_set(hotel_rate_split, strata = avg_price_per_room)
