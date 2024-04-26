library(modeldatatoo)

chimiometrie_2019 <-
  data_chimiometrie_2019()  %>%
  select(-soy_oil, -lucerne)

barley_breaks <- (0:27) * 2

set.seed(101)
barley_split <- initial_validation_split(chimiometrie_2019, prop = c(0.7, 0.15), strata = barley)
barley_train <- training(barley_split)
barley_val <- validation(barley_split)
barley_test <- testing(barley_split)
barley_rs <- validation_set(barley_split)

wave <- tibble(index = 1:550, wavelength = seq(1300, 2398, by = 2))
wave_corr <- 
  barley_train %>% 
  select(starts_with("wv")) %>% 
  cor()
wave_corr <- wave_corr[upper.tri(wave_corr)]

chimiometrie_2019$barley_bin <-
  cut(chimiometrie_2019$barley,
      breaks = barley_breaks,
      include.lowest = TRUE) 
