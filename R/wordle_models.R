# pak::pak(c("tidymodels/yardstick#525"), ask = FALSE)
library(tidymodels)
library(probably)
library(bonsai)
library(rules)
library(fs)
library(doFuture)
rlang::check_installed(c("C50", "brulee"))

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
options(future.globals.maxSize = 5.0 * 1e9)

plan("multisession")

# ------------------------------------------------------------------------------

load("RData/one_user_data_splits.RData")

# ------------------------------------------------------------------------------
# Basic preprocessing via recipes

word_rec <-
  recipe(tries ~ ., data = word_train) %>%
  step_zv(all_predictors())

norm_rec <-
  word_rec %>%
  step_normalize(all_numeric_predictors())

# ------------------------------------------------------------------------------
# Various metrics 

kap_quad <- metric_tweak("kap_quad", kap, weighting = "quadratic")

kap_lin <- metric_tweak("kap_lin", kap, weighting = "linear")

cls_mtr <- metric_set(ranked_prob_score, brier_class, kap, kap_quad, kap_lin,
                      accuracy, roc_auc)

# ------------------------------------------------------------------------------
# Boosting trees via C5.0

bst_spec <-
  boost_tree(
    trees = tune(),
    min_n = tune()
  ) %>%
  set_engine("C5.0") %>%
  set_mode("classification")

bst_wflow <- workflow(word_rec, bst_spec)

bst_param <- 
  bst_wflow %>% 
  extract_parameter_set_dials() %>% 
  update(
    min_n = min_n(c(2, 100))
  )

bst_res <-
  bst_wflow %>%
  tune_grid(
    resamples = word_rs,
    grid = 25,
    param_info = bst_param,
    metrics = cls_mtr,
    control = control_grid(save_pred = TRUE, save_workflow = TRUE)
  )

# autoplot(bst_res, metric = "ranked_prob_score")

bst_best <- select_best(bst_res, metric = "ranked_prob_score")

bst_bt_mtr <- 
  bst_res %>%
  collect_metrics() %>%
  inner_join(bst_best %>% select(.config), by = join_by(.config)) %>% 
  select(resampling = mean, n, std_err, .metric)
bst_bt_mtr


bst_oob_pred <-
  bst_res %>%
  collect_predictions(parameters = bst_best, summarize = TRUE)

set.seed(121)
bst_bt_perm_mtr <- 
  bst_oob_pred %>%
  permutations(permute = c(tries), times = 50) %>%
  mutate(
    data = map(splits, ~ analysis(.x)),
    .metrics = map(data, ~ cls_mtr(.x, truth = tries, estimate = .pred_class, 
                                   .pred_2:.pred_X))
  ) %>%
  select(.metrics) %>%
  unnest(.metrics) %>%
  summarize(
    permuted = mean(.estimate),
    .by = c(.metric)
  )

# bst_oob_pred %>%
#   conf_mat(tries, .pred_class)

# bst_oob_pred %>%
#   select(tries, .pred_2:.pred_X, .row) %>%
#   pivot_longer(cols = c(.pred_2:.pred_X), names_to = "class", values_to = "prob") %>%
#   ggplot(aes(x = prob)) +
#   geom_histogram(col = "white") +
#   facet_wrap(~tries)

# bst_oob_pred %>%
#   cal_plot_windowed(
#     truth = tries,
#     .pred_2:.pred_X,
#     step_size = 0.025,
#     window_size = 0.15
#   )

## Finalize and fit on training set

bst_final_wflow <- 
  bst_wflow %>% 
  finalize_workflow(bst_best)

set.seed(481)
bst_final <- last_fit(bst_final_wflow, word_split, metrics = cls_mtr)

bst_tidy <- 
  bst_final %>% 
  extract_workflow() %>% 
  tidy(trees = bst_best$trees)

bst_te_mtr <- 
  collect_metrics(bst_final) %>% 
  select(.metric, test = .estimate)

bst_te_pred <- collect_predictions(bst_final)

bst_mtr <- 
  bst_bt_mtr %>% 
  full_join(bst_te_mtr, by = ".metric") %>% 
  full_join(bst_bt_perm_mtr, by = ".metric")

print(bst_mtr)
print(word_split)
# ------------------------------------------------------------------------------
# RuleFit 
# 
# rule_spec <- 
#   rule_fit(learn_rate = tune(), tree_depth = tune(), 
#            trees = tune(), min_n = tune(), penalty = tune()) %>% 
#   set_mode("classification")
# 
# rule_wflow <- workflow(norm_rec, rule_spec)
# 
# rule_res <-
#   rule_wflow %>%
#   tune_bayes(
#     resamples = word_rs,
#     initial = 7,
#     iter = 20,
#     metrics = cls_mtr,
#     control = control_bayes(verbose_iter = TRUE, save_pred = TRUE, 
#                             save_workflow = TRUE, no_improve = Inf)
#   )
# 
# # autoplot(rule_res, metric = "ranked_prob_score")
# 
# rule_best <- select_best(rule_res, metric = "ranked_prob_score")
# 
# rule_bt_mtr <- 
#   rule_res %>%
#   collect_metrics() %>%
#   inner_join(rule_best %>% select(.config), by = join_by(.config)) %>% 
#   select(resampling = mean, n, std_err, .metric)
# 
# rule_oob_pred <-
#   rule_res %>%
#   collect_predictions(parameters = rule_best, summarize = TRUE)
# 
# set.seed(121)
# rule_bt_perm_mtr <- 
#   rule_oob_pred %>%
#   permutations(permute = c(tries), times = 50) %>%
#   mutate(
#     data = map(splits, ~ analysis(.x)),
#     .metrics = map(data, ~ cls_mtr(.x, truth = tries, estimate = .pred_class, .pred_2:.pred_X))
#   ) %>%
#   select(.metrics) %>%
#   unnest(.metrics) %>%
#   summarize(
#     permuted = mean(.estimate),
#     .by = c(.metric)
#   )
# 
# # rule_oob_pred %>%
# #   conf_mat(tries, .pred_class)
# 
# # rule_oob_pred %>%
# #   select(tries, .pred_2:.pred_X, .row) %>%
# #   pivot_longer(cols = c(.pred_2:.pred_X), names_to = "class", values_to = "prob") %>%
# #   ggplot(aes(x = prob)) +
# #   geom_histogram(col = "white") +
# #   facet_wrap(~tries)
# 
# # rule_oob_pred %>%
# #   cal_plot_windowed(
# #     truth = tries,
# #     .pred_2:.pred_X,
# #     step_size = 0.025,
# #     window_size = 0.15
# #   )
# 
# ## Finalize and fit on training set
# 
# rule_final_wflow <- 
#   rule_wflow %>% 
#   finalize_workflow(rule_best)
# 
# set.seed(481)
# rule_final <- last_fit(rule_final_wflow, word_split, metrics = cls_mtr)
# 
# rule_tidy <- 
#   rule_final %>% 
#   extract_workflow() %>% 
#   tidy(penalty = rule_best$penalty)
# 
# rule_te_mtr <- 
#   collect_metrics(rule_final) %>% 
#   select(.metric, test = .estimate)
# 
# rule_te_pred <- collect_predictions(rule_final)
# 
# rule_mtr <- 
#   rule_bt_mtr %>% 
#   full_join(rule_te_mtr, by = ".metric") %>% 
#   full_join(rule_bt_perm_mtr, by = ".metric")
# 
# # ------------------------------------------------------------------------------
# 
# save(rule_oob_pred, rule_te_pred, rule_tidy, rule_mtr,
#      bst_oob_pred, bst_te_pred, bst_tidy, bst_mtr, 
#      file = "RData/one_user_results.RData")
# 
# # ------------------------------------------------------------------------------

if (!interactive()) {
  q("no")
}

