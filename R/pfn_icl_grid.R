# pak::pak(c("tidymodels/brulee@tabilcl"), ask = FALSE)
library(tidymodels)
library(bestNormalize)
library(furrr)
library(splines)
library(tabpfn)


# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
# plan("multisession")

# ------------------------------------------------------------------------------

load("~/content/website/RData/forested_data.RData")

# ------------------------------------------------------------------------------

rec <-
 recipe(class ~ ., data = forested_train) |>
 step_orderNorm(all_numeric_predictors())

fit <- tab_pfn(class ~ ., data = forested_train)

sizes <- unique(floor(2^seq(2, 12, by = 1 / 2)))
reps <- seq_len(25)
sample_grid <- crossing(sizes = sizes, reps = reps)

# ------------------------------------------------------------------------------

compute_metrics_pfn <- function(i, seed) {
 suppressPackageStartupMessages(require(tidymodels))
 suppressPackageStartupMessages(require(bestNormalize))
 suppressPackageStartupMessages(require(brulee))

 n <- nrow(forested_train)

 set.seed(seed)
 split <- initial_split(forested_train, prop = i / n, strata = class)

 mtr_set <- metric_set(brier_class, roc_auc)
 set.seed(2823)
 tmp <- split |> analysis()
 icl_fit <- tab_pfn(
  rec,
  data = tmp,
  num_estimators = 1
 )

 icl_pred <-
  try(
   icl_fit |>
    predict(forested_test) |>
    bind_cols(forested_test),
   silent = TRUE
  )

 if (!inherits(icl_pred, "try-error")) {
  res <- mtr_set(icl_pred, class, .pred_Yes)  |>
   mutate(samples = i, seed = seed, model = "TabPFN")
 } else {
  res <-
   tibble::tribble(
    ~.metric, ~.estimator,   ~.estimate,
    "brier_class",    "binary",     NA_real_,
    "roc_auc",    "binary",     NA_real_,
   ) |>
   mutate(samples = i, seed = seed, model = "TabPFN")
 }

 if (seed == 1) {
  icl_pred <-
   icl_pred |>
   mutate(sample = i, model = "TabPFN") |>
   select(.pred_Yes, class, sample, model) |>
   add_rowindex() |>
   filter(.row %in% c(93L, 608L, 631L, 733L, 792L, 919L))
 } else {
  icl_pred <- NULL
 }

 list(stats = res, pred = icl_pred)
}

pfn_icl_bench <- map2(sample_grid$sizes, sample_grid$reps, compute_metrics_pfn)
pfn_icl_metrics <- map_dfr(pfn_icl_bench, ~ .x$stats)
pfn_icl_predictions <- map_dfr(pfn_icl_bench, ~ .x$pred)

pfn_icl_metrics |>
 ggplot(aes(samples, .estimate)) +
 geom_point(alpha = 1 / 10, cex = 1) +
 facet_wrap(~ .metric, scales = "free_y") +
 scale_x_continuous(transform = scales::log2_trans()) +
 geom_smooth(span = 2/3, method = 'loess', formula = 'y ~ x', se = FALSE, col = "#009F3FFF") +
 geom_quantile(formula = y ~ ns(x, 3), quantiles = c(0.05, 0.95), col = "#8FDA04FF")

pfn_icl_predictions |>
 ggplot(aes(sample, .pred_Yes)) +
 geom_point(alpha = 1 / 10, cex = 1) +
 facet_wrap(~ .row) +
 scale_x_continuous(transform = scales::log2_trans()) +
 geom_smooth(span = 2/3, method = 'loess', formula = 'y ~ x', se = FALSE, col = "#009F3FFF")

save(pfn_icl_metrics, pfn_icl_predictions, file = "pfn_icl_bench.RData")
