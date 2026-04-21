compare_models <- function(set,
                           equiv = 0.01,
                           current = "$.",
                           metric = "brier_class",
                           key = NULL,
                           ...) {
  mtr_set <-
    set$result[[1]] |>
    .get_tune_metrics()
  mtr_info <-
    dplyr::as_tibble(mtr_set) |>
    dplyr::filter(metric == !!metric)
  
  # Get workflows and models
  combos <-
    set$wflow_id |>
    purrr::map( ~ extract_workflow(all_sets, id = .x)) |>
    purrr::map(extract_spec_parsnip) |>
    purrr::map_dfr( ~ dplyr::tibble(class = class(.x)[1], engine = .x$engine))
  combos$label <- set$wflow_id
  
  combos$class[combos$label == "C5.0 Rules"] <- "C5_rules"
  
  # exclude current
  best_mtr <-
    rank_results(set, rank_metric = metric, select_best = TRUE) |>
    dplyr::filter(.metric == mtr_info$metric)
  
  if (mtr_info$direction == "minimize") {
    best_mtr <- best_mtr |> dplyr::arrange(mean)
  } else {
    best_mtr <- best_mtr |> dplyr::arrange(dplyr::desc(mean))
  }
  
  best_id <- best_mtr |>
    dplyr::filter(!grepl(current, wflow_id)) |>
    dplyr::slice(1) |>
    purrr::pluck("wflow_id")
  
  other_ids <-
    best_mtr |>
    dplyr::slice(-1) |>
    purrr::pluck("wflow_id")
  
  num_others <- length(other_ids)
  
  score_perf <- perf_mod(set, metric = metric, ...)
  
  score_post <-
    score_perf |>
    tidy() |>
    dplyr::summarise(
      median = median(posterior),
      lower = quantile(posterior, 0.05),
      upper = quantile(posterior, 0.95),
      .by = c(model)
    ) |>
    dplyr::inner_join(combos |> dplyr::rename(model = label), by = "model")
  
  best_list <- rep(best_id, num_others)
  other_list <- other_ids
  
  diff_obj <-
    score_perf |>
    contrast_models(list_1 = best_list, list_2 = other_ids)
  
  diff_sum <-
    diff_obj |>
    summary(size = equiv) |>
    dplyr::mutate(
      model = gsub(paste(best_id, "vs "), "", contrast),
      pract_equiv = ifelse(pract_equiv < 0.01, 0.01, pract_equiv)
    )  |>
    dplyr::select(
      model,
      probability,
      mean_diff = mean,
      lower_diff = lower,
      upper_diff = upper,
      size,
      dplyr::starts_with("pract")
    )
  dplyr::full_join(score_post, diff_sum, by = "model") |>
    dplyr::relocate(model, class, engine)
}
