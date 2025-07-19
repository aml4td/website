library(tidymodels)
library(bestNormalize)
library(ncvreg)
# pak::pak(c("trevorhastie/uniLasso"), ask = FALSE)
library(uniLasso)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

load("RData/forested_data.RData")

glmn_rec <-
  recipe(class ~ elevation + temp_annual_mean, data = forested_train) %>%
  step_orderNorm(all_predictors()) |>
  prep()

norm_train <- bake(glmn_rec, new_data = NULL)

# ------------------------------------------------------------------------------

mle_est <-
  logistic_reg() |>
  fit(class ~ ., data = norm_train) |>
  tidy() |>
  filter(term != "(Intercept)") |>
  left_join(name_key |> rename(term = variable), by = "term") |>
  mutate(
    Term = case_when(
      term == "elevation" ~ "Elevation",
      TRUE ~ tools::toTitleCase(text)
    )
  )

# ------------------------------------------------------------------------------

ridge_pens <- 10^seq(-5, 2, length.out = 50)

lr_ridge_spec <-
  logistic_reg(penalty = tune(), mixture = 0) |>
  set_engine("glmnet", path_values = ridge_pens)

lr_ridge_coef <- NULL
for (i in seq_along(ridge_pens)) {
  tmp <-
    lr_ridge_spec |>
    finalize_model(tibble(penalty = ridge_pens[i])) |>
    fit(class ~ ., data = norm_train) |>
    tidy(penalty = ridge_pens[i])
  
  lr_ridge_coef <- bind_rows(lr_ridge_coef, tmp)
}

lr_ridge_coef <-
  lr_ridge_coef |>
  filter(term != "(Intercept)") |>
  left_join(name_key |> rename(term = variable), by = "term") |>
  mutate(
    Term = case_when(
      term == "elevation" ~ "Elevation",
      TRUE ~ tools::toTitleCase(text)
    ),
    method = "Ridge"
  )

# lr_ridge_coef |>
#   ggplot(aes(penalty, estimate, col = Term)) +
#   geom_hline(data = mle_est, aes(yintercept = estimate, col = Term), lty = 2) +
#   geom_line() +
#   geom_point() +
#   scale_x_log10()

# ------------------------------------------------------------------------------

lasso_pens <- 10^seq(-4.5, 0, length.out = 50)

lr_lasso_spec <-
  logistic_reg(penalty = tune(), mixture = 1) |>
  set_engine("glmnet", path_values = lasso_pens)

lr_lasso_coef <- NULL
for (i in seq_along(lasso_pens)) {
  tmp <-
    lr_lasso_spec |>
    finalize_model(tibble(penalty = lasso_pens[i])) |>
    fit(class ~ ., data = norm_train) |>
    tidy(penalty = lasso_pens[i])
  
  lr_lasso_coef <- bind_rows(lr_lasso_coef, tmp)
}

lr_lasso_coef <-
  lr_lasso_coef |>
  filter(term != "(Intercept)") |>
  left_join(name_key |> rename(term = variable), by = "term") |>
  mutate(
    Term = case_when(
      term == "elevation" ~ "Elevation",
      TRUE ~ tools::toTitleCase(text)
    ),
    method = "Lasso"
  )

# lr_lasso_coef |>
#   ggplot(aes(penalty, estimate, col = Term))  +
#   geom_hline(data = mle_est, aes(yintercept = estimate, col = Term), lty = 2) +
#   geom_line() +
#   geom_point() +
#   scale_x_log10()

# ------------------------------------------------------------------------------

glmn_pens <- 10^seq(-5, 0, length.out = 50)
mix <- (1:9) / 10

lr_glmn_coef <- NULL
for (j in seq_along(mix)) {
  for (i in seq_along(glmn_pens)) {
    lr_glmn_spec <-
      logistic_reg(penalty = tune(), mixture = mix[j]) |>
      set_engine("glmnet", path_values = glmn_pens)
    
    tmp <-
      lr_glmn_spec |>
      finalize_model(tibble(penalty = glmn_pens[i])) |>
      fit(class ~ ., data = norm_train) |>
      tidy(penalty = glmn_pens[i]) |>
      mutate(mixture = mix[j])
    
    lr_glmn_coef <- bind_rows(lr_glmn_coef, tmp)
  }
}
lr_glmn_coef <-
  lr_glmn_coef |>
  filter(term != "(Intercept)") |>
  left_join(name_key |> rename(term = variable), by = "term") |>
  mutate(
    Term = case_when(
      term == "elevation" ~ "Elevation",
      TRUE ~ tools::toTitleCase(text)
    ),
    method = "glmnet"
  )

# lr_glmn_coef |>
#   ggplot(aes(penalty, estimate, col = Term))  +
#   geom_hline(data = mle_est, aes(yintercept = estimate, col = Term), lty = 2) +
#   geom_line() +
#   geom_point() +
#   scale_x_log10() +
#   facet_wrap(~ mixture)

# ------------------------------------------------------------------------------

scad_pens <- 10^seq(-2, 0, length.out = 50)
gam <- seq(4, 40, by = 4)

norm_train_x <- as.matrix(norm_train |> select(-class))

tidy.ncvreg <- function(x, ...) {
  coef(x) |>
    t() |>
    tibble::as_tibble(rownames = "penalty") |>
    mutate(penalty = as.numeric(penalty)) |>
    tidyr::pivot_longer(
      cols = c(-penalty),
      names_to = "term",
      values_to = "estimate"
    )
}

# tmp <-
#   ncvreg(norm_train_x, norm_train$class, family = "binomial", penalty = "SCAD",
#        lambda = scad_pens, gamma = 3)

lr_scad_coef <- NULL
for (j in seq_along(gam)) {
  tmp <-
    ncvreg(
      norm_train_x,
      norm_train$class,
      family = "binomial",
      penalty = "SCAD",
      lambda = scad_pens,
      gamma = gam[j]
    ) |>
    tidy() |>
    mutate(gamma = gam[j])
  
  lr_scad_coef <- bind_rows(lr_scad_coef, tmp)
}

lr_scad_coef <-
  lr_scad_coef |>
  filter(term != "(Intercept)") |>
  left_join(name_key |> rename(term = variable), by = "term") |>
  mutate(
    Term = case_when(
      term == "elevation" ~ "Elevation",
      TRUE ~ tools::toTitleCase(text)
    ),
    method = "SCAD"
  )

# lr_scad_coef |>
#   ggplot(aes(penalty, estimate, col = Term))  +
#   geom_hline(data = mle_est, aes(yintercept = estimate, col = Term), lty = 2) +
#   geom_line() +
#   geom_point() +
#   scale_x_log10() +
#   facet_wrap(~ gamma)

# ------------------------------------------------------------------------------

mcp_pens <- 10^seq(-2, 0, length.out = 50)
gam <- seq(4, 40, by = 4)

norm_train_x <- as.matrix(norm_train |> select(-class))

tidy.ncvreg <- function(x, ...) {
  coef(x) |>
    t() |>
    tibble::as_tibble(rownames = "penalty") |>
    mutate(penalty = as.numeric(penalty)) |>
    tidyr::pivot_longer(
      cols = c(-penalty),
      names_to = "term",
      values_to = "estimate"
    )
}


lr_mcp_coef <- NULL
for (j in seq_along(gam)) {
  tmp <-
    ncvreg(
      norm_train_x,
      norm_train$class,
      family = "binomial",
      penalty = "MCP",
      lambda = mcp_pens,
      gamma = gam[j]
    ) |>
    tidy() |>
    mutate(gamma = gam[j])
  
  lr_mcp_coef <- bind_rows(lr_mcp_coef, tmp)
}

lr_mcp_coef <-
  lr_mcp_coef |>
  filter(term != "(Intercept)") |>
  left_join(name_key |> rename(term = variable), by = "term") |>
  mutate(
    Term = case_when(
      term == "elevation" ~ "Elevation",
      TRUE ~ tools::toTitleCase(text)
    ),
    method = "MCP"
  )

# lr_mcp_coef |>
#   ggplot(aes(penalty, estimate, col = Term))  +
#   geom_hline(data = mle_est, aes(yintercept = estimate, col = Term), lty = 2) +
#   geom_line() +
#   geom_point() +
#   scale_x_log10() +
#   facet_wrap(~ gamma)

# ------------------------------------------------------------------------------

uni_pens <- 10^seq(-3, 0, length.out = 50)

uni_fit <- uniLasso(
  norm_train_x,
  ifelse(norm_train$class == "Yes", 0, 1),
  family = "binomial",
  lambda.min.ratio = 0,
  lambda = uni_pens
) 

lr_uni_coef <- 
  predict(uni_fit, type = "coefficients", s = uni_pens) |> 
  as.matrix() |> 
  as_tibble(rownames = "term") |> 
  pivot_longer(cols = c(-term), values_to = "estimate", names_to = "s") |> 
  mutate(penalty = rep(uni_pens, 3)) |> 
  filter(term != "(Intercept)")  |>
  left_join(name_key |> rename(term = variable), by = "term") |>
  mutate(
    Term = case_when(
      term == "elevation" ~ "Elevation",
      TRUE ~ tools::toTitleCase(text)
    ),
    method = "UniLasso"
  )

# lr_uni_coef |>
#   ggplot(aes(penalty, estimate, col = Term))  +
#   geom_hline(data = mle_est, aes(yintercept = estimate, col = Term), lty = 2) +
#   geom_line() +
#   geom_point() +
#   scale_x_log10() 

# ------------------------------------------------------------------------------

glmn_spec <- 
  logistic_reg(penalty = 0.05, mixture = 1 / 2) |> 
  set_engine("glmnet", path_values = !!glmn_pens)

glmn_rec <-
  recipe(class ~ elevation + temp_annual_mean, data = forested_train) %>%
  step_orderNorm(all_predictors()) 

glmn_wflow <- workflow(glmn_rec, glmn_spec)

set.seed(382)
glmn_boot_coef <- forested_train |> 
  select(class, elevation, temp_annual_mean) |> 
  bootstraps(times = 2000) |> 
  mutate(
    fits = purrr::map(splits, ~ fit(glmn_wflow,  data = analysis(.x))),
    coef = purrr::map(fits, tidy)
  ) |> 
  select(coef, id) |> 
  unnest(coef) |> 
  filter(term != "(Intercept)") |> 
  left_join(name_key |> rename(term = variable), by = "term") |> 
  mutate(
    text = ifelse(is.na(text), term, text),
    term = tools::toTitleCase(text)
  ) |> 
  select(term, estimate)

# ------------------------------------------------------------------------------


all_penalties <- 
  bind_rows(lr_glmn_coef, lr_lasso_coef, lr_mcp_coef, lr_ridge_coef, 
            lr_scad_coef, lr_uni_coef) |> 
  select(estimate, Term, penalty, mixture, gamma, method)

save(all_penalties, glmn_boot_coef, mle_est, file = "RData/all_penalties.RData")
