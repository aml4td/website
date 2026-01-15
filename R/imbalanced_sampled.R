library(tidymodels)
library(themis)
library(discrim)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

data(myopia, package = "aplore3")
myopia_df <-
  myopia |>
  as_tibble() |>
  select(-id) |>
  rename(
    year = studyyear,
    class = myopic,
    age = age,
    female = gender,
    spherical_equivalent_refraction = spheq,
    axial_length = al,
    anterior_chamber_depth = acd,
    lens_thickness = lt,
    vitreous_chamber_depth = vcd,
    hours_sports = sporthr,
    hours_reading = readhr,
    hours_gaming = comphr,
    hours_studying = studyhr,
    hours_tv = tvhr,
    near_work_activities = diopterhr,
    mother_myopic = mommy,
    father_myopic = dadmy
  ) |>
  mutate(
    class = factor(tolower(class), levels = c("yes", "no")),
    female = if_else(female == "Female", 1, 0),
    mother_myopic = if_else(mother_myopic == "Yes", 1, 0),
    father_myopic = if_else(father_myopic == "Yes", 1, 0)
  ) |>
  select(class, spherical_equivalent_refraction, vitreous_chamber_depth)

# ------------------------------------------------------------------------------

set.seed(3571)
myopia_split <- initial_split(myopia_df, strata = class)
myopia_train <- training(myopia_split)
myopia_test <- testing(myopia_split)

# ------------------------------------------------------------------------------

min_to_max <- sum(myopia_train$class == "yes") /
  sum(myopia_train$class == "No")
max_to_min <- 1 / min_to_max

smol_class_orig <- myopia_train |> mutate(Data = "Original")

ser_rng <- range(myopia_train$spherical_equivalent_refraction)
vcd_rng <- range(myopia_train$vitreous_chamber_depth)

# ------------------------------------------------------------------------------

seed <- 322

set.seed(seed)
smol_class_down <-
  recipe(class ~ ., data = myopia_train) |>
  step_downsample(class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "Downsampled")

set.seed(seed)
smol_class_smote <-
  recipe(class ~ ., data = myopia_train) |>
  step_smote(class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "SMOTE")

set.seed(seed)
smol_class_rose <-
  recipe(class ~ ., data = myopia_train) |>
  step_rose(
    class,
    minority_smoothness = 1 / 2,
    majority_smoothness = 1 / 2,
    over_ratio = 0.98
  ) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "ROSE")

# smol_class_rose |> count(class)

set.seed(seed)
smol_class_near_miss <-
  recipe(class ~ ., data = myopia_train) |>
  step_nearmiss(class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "Near Miss")

set.seed(seed)
smol_class_tomek <-
  recipe(class ~ ., data = myopia_train) |>
  step_tomek(class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "Tomek")

set.seed(seed)
smol_class_adasyn <-
  recipe(class ~ ., data = myopia_train) |>
  step_adasyn(class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "Adaptive Synthetic Algorithm")

imbalanced_sampled <-
  bind_rows(
    smol_class_orig,
    smol_class_down,
    smol_class_smote,
    smol_class_rose,
    smol_class_near_miss,
    smol_class_adasyn,
    smol_class_tomek,
  )

# ------------------------------------------------------------------------------

fda_fits <- function(dat) {
  fda_wflow <-
    workflow(
      class ~ spherical_equivalent_refraction + vitreous_chamber_depth,
      discrim_flexible(prod_degree = 2)
    )
  fda_fit <- fda_wflow |> fit(dat)
  fda_fit
}

smol_grid <-
  crossing(
    spherical_equivalent_refraction = seq(
      ser_rng[1],
      ser_rng[2],
      length.out = 100
    ),
    vitreous_chamber_depth = seq(vcd_rng[1], vcd_rng[2], length.out = 100)
  )

imbalanced_fda <-
  imbalanced_sampled |>
  group_nest(Data, keep = TRUE) |>
  mutate(
    fits = map(data, fda_fits),
    grid = map2(
      fits,
      Data,
      ~ augment(.x, new_data = smol_grid) |> mutate(Data = .y)
    ),
    hits = map(
      fits,
      ~ augment(.x, new_data = myopia_train |> filter(class == "yes"))
    ),
    num_hits = map_int(hits, ~ sum(.x$.pred_class == "yes"))
  )

imbalanced_grid <-
  imbalanced_fda |>
  select(grid) |>
  unnest(grid) |>
  select(-.pred_class, -.pred_no) |>
  filter(!is.na(.pred_yes))

imbalanced_hits <- imbalanced_fda$num_hits
names(imbalanced_hits) <- imbalanced_fda$Data

# ------------------------------------------------------------------------------

save(
  imbalanced_sampled,
  imbalanced_grid,
  imbalanced_hits,
  file = "RData/imbalanced_sampled.RData"
)
