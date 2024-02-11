# uses about 8GB memory and requires java + rJava
options(java.parameters = "-Xmx10g")
library("bartMachine", character.only = TRUE) # Try to stop renv from grabbing it
library(tidymodels)

# ------------------------------------------------------------------------------

tidymodels_prefer()

# ------------------------------------------------------------------------------

source("R/setup_deliveries.R")

tr_x <- delivery_train %>% select(-time_to_delivery) %>% as.data.frame()
tr_y <- delivery_train$time_to_delivery

# ------------------------------------------------------------------------------

bart_interactions <- function(x, y, ...) {
  x <- as.data.frame(x)
  mod <- bartMachine::bartMachine(x, y, ..., verbose = FALSE)

  res <- bartMachine::interaction_investigator(mod, plot = FALSE)
  keep_ind <- upper.tri(res$interaction_counts_avg)
  dim_names <- colnames(res$interaction_counts_avg)

  mean_int <- res$interaction_counts_avg[keep_ind]
  sd_int <- res$interaction_counts_sd[keep_ind]

  bart_int_res <-
    tidyr::crossing(ind_1 = seq_along(dim_names), ind_2 = seq_along(dim_names)) %>%
    dplyr::mutate(
      var_1 = dim_names[ind_1],
      var_2 = dim_names[ind_2]
    ) %>%
    dplyr::filter(ind_2 > ind_1) %>%
    dplyr::select(-ind_1, -ind_2) %>%
    dplyr::mutate(
      mean = mean_int,
      sd = sd_int,
      interaction = paste0(var_2, "_x_", var_1),
      interaction = factor(interaction),
      interaction = reorder(interaction, mean)
    ) %>%
    dplyr::arrange(dplyr::desc(mean + sd))
  bart_int_res
}

# ------------------------------------------------------------------------------

set.seed(3892)
bart_int_imp <-
  bart_interactions(tr_x, tr_y, num_trees = 500, num_burn_in = 500, seed = 584)

bart_interaction_res <-
  bart_int_imp %>%
  mutate(
    split_up = map(interaction, ~ strsplit(as.character(.x), "_x_")[[1]]),
    split_up = map(split_up, ~ sort(.x)),
    interaction = map_chr(split_up, ~ paste(.x[1], .x[2], sep = " x ")),
    interaction = map_chr(interaction, ~ gsub("^day_", "", .x)),
    interaction = map_chr(interaction, ~ gsub("_", " ", .x)),
    interaction = reorder(interaction, mean)
  ) %>%
  select(interaction, mean) %>% 
  arrange(desc(mean))

save(bart_interaction_res, file = "RData/bart_interaction_res.RData")

q("no")
