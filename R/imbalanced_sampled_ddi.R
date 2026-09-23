library(tidymodels)
library(themis)
library(discrim)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

load("~/iCloud/Code/R/cluster_centers_data.RData")
cls_data$class <- factor(cls_data$class)
cls_data$B <- if_else(cls_data$class == "red", cls_data$B + 0.2, cls_data$B)
cls_data$A <- if_else(cls_data$class == "red", cls_data$A - 0.4, cls_data$A)
set.seed(372)
# cls_data <- cls_data |> slice_sample(prop = 0.5)


set.seed(8373)
blue_data <- 
  cls_data |> filter(class == "blue") |> 
  slice_sample(n = 400)
red_data <- 
  cls_data |> 
  filter(class == "red") |> 
  mutate(tmp = 0 + 1/2 * A) |> 
  filter(B > tmp) |> 
  slice_sample(n = 60) |> 
  select(-tmp)

imbal_data <- 
  bind_rows(blue_data, red_data) |> 
  mutate(class = factor(class, levels = c("red", "blue")))

save(imbal_data, file = "RData/imbal_data.RData")

# ------------------------------------------------------------------------------

set.seed(3571)
imbal_split <- initial_split(imbal_data, strata = class)
imbal_train <- training(imbal_split)
imbal_test <- testing(imbal_split)

# ------------------------------------------------------------------------------

min_to_max <- sum(imbal_train$class == "red") /
  sum(imbal_train$class == "blue")
max_to_min <- 1 / min_to_max

smol_class_orig <- imbal_train |> mutate(Data = "Original")

ser_rng <- range(imbal_train$A)
vcd_rng <- range(imbal_train$B)

# ------------------------------------------------------------------------------

seed <- 322

set.seed(seed)
smol_class_down <-
  recipe(class ~ ., data = imbal_train) |>
  step_downsample(class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "Downsampled")

set.seed(seed)
smol_class_smote <-
  recipe(class ~ ., data = imbal_train) |>
  step_smote(class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "SMOTE")

set.seed(seed)
smol_class_rose <-
  recipe(class ~ ., data = imbal_train) |>
  step_rose(class, over_ratio = 0.98) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "ROSE")

# smol_class_rose |> count(class)

set.seed(seed)
smol_class_near_miss <-
  recipe(class ~ ., data = imbal_train) |>
  step_nearmiss(class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "Near Miss")

set.seed(seed)
smol_class_tomek <-
  recipe(class ~ ., data = imbal_train) |>
  step_tomek(class) |>
  prep() |>
  bake(new_data = NULL) |>
  mutate(Data = "Tomek")

set.seed(seed)
smol_class_adasyn <-
  recipe(class ~ ., data = imbal_train) |>
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
      class ~ A + B,
      discrim_flexible(prod_degree = 2)
    )
  fda_fit <- fda_wflow |> fit(dat)
  fda_fit
}

smol_grid <-
  crossing(
    A = seq(
      ser_rng[1],
      ser_rng[2],
      length.out = 100
    ),
    B = seq(vcd_rng[1], vcd_rng[2], length.out = 100)
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
      ~ augment(.x, new_data = imbal_train |> filter(class == "red"))
    ),
    num_hits = map(hits, ~ c(sum(.x$.pred_class == "red"), sum(.x$class == "red")))
  )

imbalanced_grid <-
  imbalanced_fda |>
  select(grid) |>
  unnest(grid) |>
  select(-.pred_class, -.pred_blue) |>
  filter(!is.na(.pred_red))

imbalanced_hits <- imbalanced_fda$num_hits
names(imbalanced_hits) <- imbalanced_fda$Data

# ------------------------------------------------------------------------------

save(
  imbalanced_sampled,
  imbalanced_grid,
  imbalanced_hits,
  file = "RData/imbalanced_sampled2.RData"
)
