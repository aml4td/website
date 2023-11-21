data(ames, package = "modeldata")

ames <-
  ames %>%
  select(Sale_Price, Bldg_Type, Neighborhood, Year_Built, Gr_Liv_Area, Full_Bath,
         Half_Bath, Year_Sold, Lot_Area, Central_Air, Longitude, Latitude) %>%
  mutate(
    Sale_Price = log10(Sale_Price),
    Baths = Full_Bath  + Half_Bath/2
  ) %>%
  select(-Half_Bath, -Full_Bath)

## TODO pre-compute date fields, is_renovated instead of date
## TODO use more regular grids
## TODO run FSA to look for interactions

set.seed(3024)
ames_split <- initial_split(ames, strata = Sale_Price, breaks = 5)

ames_train <- training(ames_split)
ames_test  <- testing(ames_split)

set.seed(6268)
ames_rs <- vfold_cv(ames_train, strata = Sale_Price)
