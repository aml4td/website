renv::deactivate(clean = TRUE)

# restarts

pak::pak(c("renv"), ask = FALSE)

# Also update dev packages to cran versions (where needed)ren

renv::init()

# choose option #1

# check
renv::status()

renv::snapshot()
