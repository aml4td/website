library(tidymodels)
library(sparsevctrs)
library(lobstr)
library(readr)
library(future)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
plan(strategy = "multisession", workers = parallel::detectCores())

# ------------------------------------------------------------------------------

# https://pubs.acs.org/doi/10.1021/acs.jcim.5c01192
# Specifically: https://pubs.acs.org/doi/suppl/10.1021/acs.jcim.5c01192/suppl_file/ci5c01192_si_003.zip

cyp3A4_outcome <-
  read_csv("~/Downloads/Dataset 3/3a4_Y_MACCS_.csv", col_names = FALSE) |>
  rlang::set_names("class") |>
  mutate(
    class = case_when(
      class == 0 ~ "inactive",
      class == 1 ~ "low",
      TRUE ~ "inhibitor"
    )
  )
low_risk <- which(cyp3A4_outcome == "low")
cyp3A4_outcome <- cyp3A4_outcome[-low_risk, ]
cyp3A4_outcome$class <-
  factor(cyp3A4_outcome$class, levels = c("inhibitor", "inactive"))

mean(cyp3A4_outcome$class == "inhibitor") * 100

# ------------------------------------------------------------------------------

# Klekota-Roth fingerprints
cyp3A4_KRFP <- read_csv(
  "~/Downloads/Dataset 3/KRFP/3a4_X_KRFP_.csv",
  col_names = FALSE
)
cli::cli_inform(
  "There were {ncol(cyp3A4_KRFP)} Klekota-Roth fingerprint columns"
)
original_cols <- ncol(cyp3A4_KRFP)

# Remove low-risk compounds
cyp3A4_KRFP <- cyp3A4_KRFP[-low_risk, ]
all.equal(nrow(cyp3A4_outcome), nrow(cyp3A4_KRFP))

zv_KRFP <- cyp3A4_KRFP |> map_lgl(~ vctrs::vec_unique_count(.x) == 1)
cyp3A4_KRFP <- cyp3A4_KRFP[, !zv_KRFP]
colnames(cyp3A4_KRFP) <- recipes::names0(ncol(cyp3A4_KRFP), "kr_")
cli::cli_inform(
  "There are now {ncol(cyp3A4_KRFP)} Klekota-Roth fingerprint columns"
)

###

cyp3A4_MACCS <- read_csv(
  "~/Downloads/Dataset 3/MACCS/3a4_X_MACCS_.csv",
  col_names = FALSE
)
cli::cli_inform(
  "There were {ncol(cyp3A4_MACCS)} Molecular ACCess System fingerprint columns"
)
original_cols <- c(original_cols, ncol(cyp3A4_MACCS))

# Remove low-risk compounds
cyp3A4_MACCS <- cyp3A4_MACCS[-low_risk, ]
all.equal(nrow(cyp3A4_outcome), nrow(cyp3A4_MACCS))

zv_MACCS <- cyp3A4_MACCS |> map_lgl(~ vctrs::vec_unique_count(.x) == 1)
cyp3A4_MACCS <- cyp3A4_MACCS[, !zv_MACCS]
colnames(cyp3A4_MACCS) <- recipes::names0(ncol(cyp3A4_MACCS), "maccs_")
cli::cli_inform(
  "There are now {ncol(cyp3A4_MACCS)} Molecular ACCess System fingerprint columns"
)

# PubChem
cyp3A4_PubChem <- read_csv(
  "~/Downloads/Dataset 3/PubChem/3a4_X_PubChem_.csv",
  col_names = FALSE
)
cli::cli_inform("There were {ncol(cyp3A4_PubChem)} PubChem fingerprint columns")
original_cols <- c(original_cols, ncol(cyp3A4_PubChem))

# Remove low-risk compounds
cyp3A4_PubChem <- cyp3A4_PubChem[-low_risk, ]
all.equal(nrow(cyp3A4_outcome), nrow(cyp3A4_PubChem))

zv_PubChem <- cyp3A4_PubChem |> map_lgl(~ vctrs::vec_unique_count(.x) == 1)
cyp3A4_PubChem <- cyp3A4_PubChem[, !zv_PubChem]
colnames(cyp3A4_PubChem) <- recipes::names0(ncol(cyp3A4_PubChem), "pubchem_")
cli::cli_inform(
  "There are now {ncol(cyp3A4_PubChem)} PubChem fingerprint columns"
)

# ------------------------------------------------------------------------------

cyp3A4_fp <- bind_cols(cyp3A4_KRFP, cyp3A4_MACCS, cyp3A4_PubChem)
cli::cli_inform(
  "There are now {ncol(cyp3A4_fp)} fingerprint columns"
)

# ------------------------------------------------------------------------------

names(original_cols) <- c("KR", "MACCS", "PubChem")

initial_cols <- ncol(cyp3A4_fp)

rec_linear_comb <-
  recipe(~., data = cyp3A4_fp) |>
  step_lincomb(all_predictors()) |>
  prep()

cyp3A4_fp <-
  rec_linear_comb |>
  bake(new_data = NULL) |>
  map_dfc(as.integer)

removed <- tidy(rec_linear_comb, number = 1)

final_cols <- ncol(cyp3A4_fp)

has_sparse_elements(cyp3A4_fp)
obj_size(cyp3A4_fp)
# 209.29 MB

cli::cli_inform(
  "There are now {ncol(cyp3A4_fp)} fingerprint columns"
)

# ------------------------------------------------------------------------------

save(
  cyp3A4_fp,
  cyp3A4_outcome,
  original_cols,
  initial_cols,
  final_cols,
  file = "RData/drug_interactions.RData",
  compression_level = 9
)

# ------------------------------------------------------------------------------

if (!interactive()) {
  q("no")
}
