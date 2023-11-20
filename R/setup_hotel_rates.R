
# ------------------------------------------------------------------------------
# Initially split the data and then use the date range to make the real split so
# that there are no overlapping days.

hotel_rate_split <- initial_time_split(hotel_rates, prop = 0.9)
hotel_rate_train <- training(hotel_rate_split)
hotel_rate_train_range <- range(hotel_rate_train$arrival_date)

hotel_rate_train <-
  hotel_rates %>%
  filter(arrival_date <= hotel_rate_train_range[2]) %>%
  select(-arrival_date)

hotel_rate_test <-
  hotel_rates %>%
  filter(arrival_date > hotel_rate_train_range[2])

hotel_rate_test_range <- range(hotel_rate_test$arrival_date)
hotel_rate_train_range <- format(hotel_rate_train_range, "%e %B %Y")
hotel_rate_test_range <- format(hotel_rate_test_range, "%e %B %Y")

hotel_rate_test <-
  hotel_rate_test %>%
  select(-arrival_date)

set.seed(6858)
hotel_rate_rs  <- validation_split(hotel_rate_train, strata = avg_price_per_room)
