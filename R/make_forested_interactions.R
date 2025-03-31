library(tidymodels)
library(hstats)
library(bonsai)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

load("RData/forested_data.RData")

p <- ncol(forested_train) - 2

set.seed(905)
bst_fit <-
  boost_tree(mode = "classification", trees = 1000, stop_iter = 5) |>
  set_engine("lightgbm") |>
  fit(class ~ ., data = forested_train %>% select(-zip))

set.seed(494)
bst_hstats <-
  hstats(bst_fit,
         X = forested_train %>% dplyr::select(-class, -zip),
         pairwise_m = p,
         approx = TRUE,
         n_max = 500,
         verbose = FALSE, 
         type = "prob")

bst_int_obj <- h2_pairwise(bst_hstats, zero = TRUE)

int_vars <-
  strsplit(rownames(bst_int_obj), ":") %>%
  map(sort) %>%
  map(~gsub("_0", " ", .x)) %>%
  map(~gsub("_", " ", .x)) %>%
  map_chr( ~ paste(.x[1], "x", .x[2]))

bst_ints <-
  tibble(terms = int_vars, effect = bst_int_obj$M[, 1]) %>%
  mutate(
    terms = factor(terms),
    terms = reorder(terms, effect)
  )

int_form <- 
  as.character(bst_ints$terms)[1:10] %>% 
  strsplit(., " x ") %>% 
  map(~ paste0("`", .x, "`")) %>% 
  map_chr(~ paste0(.x, collapse = ":")) %>% 
  paste0(., collapse = " + ")

int_form <- 
  paste("~", int_form) %>% 
  as.formula()

bst_ints <-
  strsplit(rownames(bst_int_obj), ":") %>%
  map(sort) %>%
  map(~gsub("_0", " ", .x)) %>%
  map(~gsub("_", " ", .x)) %>%
  map_chr( ~ paste(.x[1], "x", .x[2]))

print(int_form)

save(bst_ints, int_form, bst_int_obj, file = "RData/forested_interactions.RData")

if (!interactive()) {
  q("no")
}


