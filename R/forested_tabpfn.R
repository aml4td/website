# pak::pak(c("topepo/TabPFN"), ask = FALSE)
library(reticulate)

# ------------------------------------------------------------------------------

all_ve <- virtualenv_list()
if (any(all_ve == "aml4td-tabpfn")) {
 use_virtualenv("aml4td-tabpfn")
} else {
 python <- reticulate::install_python("3.11")

 virtualenv_install(
  "aml4td-tabpfn",
  packages = c("numpy", "tabpfn"),
  python = python
 )

 py_config()
 py_list_packages(envname = "aml4td-tabpfn", type = "virtualenv")
}

# ------------------------------------------------------------------------------

library(TabPFN)
library(tidymodels)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
class_metrics <- metric_set(brier_class, roc_auc, kap, accuracy, sensitivity,
                            specificity, mn_log_loss)

# ------------------------------------------------------------------------------

load("RData/forested_data.RData")

num_rs <- nrow(forested_rs)
pfn_assess_pred <- NULL

rs_start <- proc.time()
for (i in 1:num_rs) {
 mod_dat <- analysis(forested_rs$splits[[i]])
 perf_dat <- assessment(forested_rs$splits[[i]])

 tmp_fit <- tab_pfn(class ~ ., data = mod_dat)
 tmp_pred <-
  augment(tmp_fit, perf_dat) %>%
  mutate(id = forested_rs$id[i])
 pfn_assess_pred <- bind_rows(pfn_assess_pred, tmp_pred)
}
rs_stop <- proc.time()

rs_time <- rs_stop[3] - rs_start[3]

pfn_ind_mtr <-
 pfn_assess_pred %>%
 group_nest(id, .key = "assessment") %>%
 mutate(
  .metrics =
   map(
    assessment,
    ~ class_metrics(.x, truth = class, estimate = .pred_class, .pred_Yes)
   )
 ) %>%
 select(-assessment) %>%
 unnest(c(.metrics))

pfn_mtr <- summarize(
 pfn_ind_mtr,
 mean = mean(.estimate),
 n = length(.estimate),
 std_err = sd(.estimate) / sqrt(n),
 .by = c(.metric)
)

# ------------------------------------------------------------------------------

tr_start <- proc.time()
pfn <- tab_pfn(class ~ ., data = forested_train)

pfn_test_pred <- augment(pfn, forested_test)
tr_stop <- proc.time()

tr_time <- tr_stop[3] - tr_start[3]

pfn_test_mtr <-
 pfn_test_pred %>%
 class_metrics(class, estimate = .pred_class, .pred_Yes)

# ------------------------------------------------------------------------------

pfn_assess_pred <-
 pfn_assess_pred %>%
 select(starts_with(".pred"), class, id)

objs <- ls(pattern = "(_pred$)|(_mtr$)|(_time$)")

save(list = objs, file = "RData/pfn_results.RData", compress = TRUE)

# ------------------------------------------------------------------------------

if (!interactive()) {
 q("no")
}



