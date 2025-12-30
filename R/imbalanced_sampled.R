library(tidymodels)

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

min_to_max <- sum(myopia_df$class == "yes") /
  sum(myopia_df$class == "No")
max_to_min <- 1 / min_to_max

smol_class_orig <- myopia_df |> mutate(Data = "Original")

# ------------------------------------------------------------------------------

set.seed(121)
smol_class_down <-
  recipe(class ~ ., data = myopia_df) |>
  step_downsample(class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "Downsampled")

set.seed(121)
smol_class_smote <-
  recipe(class ~ ., data = myopia_df) |>
  step_smote(class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "SMOTE")

set.seed(121)
smol_class_rose <-
  recipe(class ~ ., data = myopia_df) |>
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

set.seed(121)
smol_class_near_miss <-
  recipe(class ~ ., data = myopia_df) |>
  step_nearmiss(class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "Near Miss")

set.seed(121)
smol_class_tomek <-
  recipe(class ~ ., data = myopia_df) |>
  step_tomek(class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "Tomek")

set.seed(121)
smol_class_adasyn <-
  recipe(class ~ ., data = myopia_df) |>
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

save(imbalanced_sampled, file = "RData/imbalanced_sampled.RData")
