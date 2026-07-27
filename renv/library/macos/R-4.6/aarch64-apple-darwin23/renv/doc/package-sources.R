## ----include=FALSE------------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----setup--------------------------------------------------------------------
# library(renv)

## -----------------------------------------------------------------------------
# repos <- c(CRAN = "https://cloud.r-project.org", WORK = "https://work.example.org")
# options(repos = repos)

## -----------------------------------------------------------------------------
# # use the latest-available Bioconductor release
# renv::init(bioconductor = TRUE)
# 
# # use a specific version of Bioconductor
# renv::init(bioconductor = "3.14")

## -----------------------------------------------------------------------------
# renv::settings$bioconductor.version("3.14")

## -----------------------------------------------------------------------------
# options(renv.bioconductor.repos = c(...))

## -----------------------------------------------------------------------------
# renv:::renv_paths_cellar()

## -----------------------------------------------------------------------------
# # please don't do this!
# `%>%` <- magrittr::`%>%`

