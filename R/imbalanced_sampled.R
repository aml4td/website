library(tidymodels)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

set.seed(121)
smol_class_dat <-
  two_class_dat |>
  filter(Class == "Class2") |>
  slice_sample(n = 100) |>
  bind_rows(two_class_dat |> filter(Class == "Class1")) |>
  mutate(
    Class = ifelse(Class == "Class1", "Majority", "Minority"),
    Class = factor(Class)
  )

# ------------------------------------------------------------------------------

min_to_max <- sum(smol_class_dat$Class == "Minority") /
  sum(smol_class_dat$Class == "Majority")
max_to_min <- 1 / min_to_max

smol_class_orig <- smol_class_dat |> mutate(Data = "Original")

# ------------------------------------------------------------------------------

set.seed(121)
smol_class_down <-
  recipe(Class ~ ., data = smol_class_dat) |>
  step_downsample(Class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "Downsampled")

set.seed(121)
smol_class_smote <-
  recipe(Class ~ ., data = smol_class_dat) |>
  step_smote(Class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "SMOTE")

set.seed(121)
smol_class_rose <-
  recipe(Class ~ ., data = smol_class_dat) |>
  step_rose(
    Class,
    minority_smoothness = 1 / 2,
    majority_smoothness = 1 / 2,
    over_ratio = 0.98
  ) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "ROSE")

# smol_class_rose |> count(Class)

set.seed(121)
smol_class_near_miss <-
  recipe(Class ~ ., data = smol_class_dat) |>
  step_nearmiss(Class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "Near Miss")

set.seed(121)
smol_class_tomek <-
  recipe(Class ~ ., data = smol_class_dat) |>
  step_tomek(Class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "Tomek")

set.seed(121)
smol_class_adasyn <-
  recipe(Class ~ ., data = smol_class_dat) |>
  step_adasyn(Class) |>
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
