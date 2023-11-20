library(modeldatatoo)

chimiometrie_2019 <-
  data_chimiometrie_2019()  %>%
  select(-soy_oil, -lucerne)

set.seed(87)
barley_split <-
  initial_split(chimiometrie_2019,
                prop = 1 - (500 / nrow(chimiometrie_2019)))
barley_not_test <- training(barley_split)
barley_test  <-  testing(barley_split)

set.seed(2323)
barley_rs <- validation_split(barley_not_test, prop = 1 - (500 / nrow(barley_not_test)))
barley_train <- analysis(barley_rs$splits[[1]])
barley_val <- assessment(barley_rs$splits[[1]])
