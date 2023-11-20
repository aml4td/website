load("../RData/deliveries.RData")

set.seed(991)
delivery_split <- initial_validation_split(deliveries, prop = c(0.6, 0.2), strata = time_to_delivery)
delivery_train <- training(delivery_split)
delivery_test  <- testing(delivery_split)
delivery_val   <- validation(delivery_split)
delivery_rs    <- validation_set(delivery_split)

