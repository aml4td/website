## ----include=FALSE------------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## -----------------------------------------------------------------------------
# # restore packages from the lockfile, bypassing the cache
# renv::restore(rebuild = TRUE)
# 
# # re-install a package
# renv::install("<package>", rebuild = TRUE)
# 
# # rebuild all packages in the project
# renv::rebuild()

## -----------------------------------------------------------------------------
# # installation of RNetCDF may require us to set include paths for netcdf
# configure.args = c(RNetCDF = "--with-netcdf-include=/usr/include/udunits2")
# options(configure.args = configure.args)
# renv::install("RNetCDF")

## -----------------------------------------------------------------------------
# options(
#   configure.args.RNetCDF = "--with-netcdf-include=/usr/include/udunits2"
# )
# renv::install("RNetCDF")

## -----------------------------------------------------------------------------
# # installation of R packages using the Windows Subsystem for Linux
# # may require the `--no-lock` flag to be set during install
# options(install.opts = "--no-lock")
# renv::install("xml2")
# 
# # alternatively, you can set such options for specific packages with e.g.
# options(install.opts = list(xml2 = "--no-lock"))
# renv::install("xml2")

## -----------------------------------------------------------------------------
# options(renv.download.override = utils::download.file)

## -----------------------------------------------------------------------------
# # use Windows' internal download machinery
# Sys.setenv(RENV_DOWNLOAD_METHOD = "wininet")
# 
# # use R's bundled libcurl implementation
# Sys.setenv(RENV_DOWNLOAD_METHOD = "libcurl")

## -----------------------------------------------------------------------------
# getOption("download.file.method")

## -----------------------------------------------------------------------------
# renv:::renv_download_method()

## -----------------------------------------------------------------------------
# Sys.setenv(RENV_DOWNLOAD_METHOD = getOption("download.file.method"))

## -----------------------------------------------------------------------------
# curl::ie_get_proxy_for_url()

## -----------------------------------------------------------------------------
# # define a function providing authentication
# options(renv.auth = function(package, record) {
#   if (package == "MyPackage")
#     return(list(GITHUB_PAT = "<pat>"))
# })
# 
# # use a named list directly
# options(renv.auth = list(
#   MyPackage = list(GITHUB_PAT = "<pat>")
# ))
# 
# # alternatively, set package-specific option
# # as a list
# options(renv.auth.MyPackage = list(GITHUB_PAT = "<pat>"))
# # as a function
# options(renv.auth.MyPackage = function(record) {
#    list(GITHUB_PAT = "<pat>")
# })

## -----------------------------------------------------------------------------
# renv::install("igraph=igraph/rigraph")

## -----------------------------------------------------------------------------
# options(renv.download.headers = function(url) {
#   if (grepl("^https://my/repository", url))
#     return(c(Authorization = Sys.getenv("AUTH_HEADER")))
# })

## -----------------------------------------------------------------------------
# options(renv.download.trace = TRUE)

