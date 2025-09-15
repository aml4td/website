library(tidymodels)
library(hstats)
library(bonsai)
library(mirai)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
daemons(parallel::detectCores())

# ------------------------------------------------------------------------------

load("RData/forested_data.RData")

p <- ncol(forested_train) - 2
top <- 5

# ------------------------------------------------------------------------------
# Compute the H statistics

set.seed(905)
bst_fit <-
  boost_tree(mode = "classification", trees = 1000, stop_iter = 5) |>
  set_engine("lightgbm") |>
  fit(class ~ ., data = forested_train %>% select(-county))

set.seed(494)
hstat_reps <- 
  future_lapply(
    1:25, 
    FUN = function(x) {
      bst_hstats <-
        hstats(bst_fit,
               X = forested_train %>% dplyr::select(-class, -county),
               pairwise_m = p,
               approx = TRUE,
               n_max = 250,
               verbose = FALSE, 
               type = "prob")
    },
    future.seed=TRUE,
    future.globals = c("forested_train", "bst_fit", "p"),
    future.packages = c("hstats", "tidymodels", "bonsai", "lightgbm")
  )
  
# ------------------------------------------------------------------------------
# Process the data so that the terms within the interactions are sorted

tidy_hstats <- function(x, ...) {
  as_tibble(x$M, rownames = "term")
}

forested_hstats <-  
  map(hstat_reps, ~ h2_pairwise(.x, zero = TRUE)) |> 
  map_dfr(tidy_hstats, .id = "replicate") |> 
  select(-.pred_No) |> 
  summarize(
    mean_score = mean(.pred_Yes),
    n = sum(!is.na(.pred_Yes)),
    std_dev_score = sd(.pred_Yes),
    std_err_score = std_dev_score / sqrt(n),
    .by = term
  ) |> 
  mutate(
    interaction_num = row_number(),
    variable = map(term, ~ sort(strsplit(.x, split = ":")[[1]])),
    term_sorted = map_chr(variable, ~ paste0(.x, collapse = ":"))
  )

# Data for presentation
forested_hstats_text <- 
  forested_hstats |> 
  unnest(variable) |> 
  full_join(name_key, by = "variable") |> 
  mutate(
    text = ifelse(is.na(text), variable, text),
    text = tools::toTitleCase(text)
  ) |> 
  summarize(
    term = paste(min(text), max(text), sep = " x "),
    mean_score = mean(mean_score),
    std_err_score = mean(std_err_score),
    .by = c(interaction_num)
  ) |> 
  arrange(desc(mean_score)) |> 
  mutate(
    term = factor(term),
    term = reorder(term, mean_score),
    .lower = mean_score - qnorm(.95) * std_err_score,
    .upper = mean_score + qnorm(.95) * std_err_score
  ) |> 
  select(-interaction_num)

# ------------------------------------------------------------------------------
# Make an R formula with the top terms

forested_int_form <- 
  forested_hstats |> 
  slice_max(mean_score, n = top) |> 
  pluck("term_sorted") |> 
  paste0(collapse = " + ")

forested_int_form <- paste("~", forested_int_form)
forested_int_form <- as.formula(forested_int_form)

# ------------------------------------------------------------------------------

save(forested_int_form, forested_hstats_text, file = "RData/forested_interactions.RData")

if (!interactive()) {
  q("no")
}


