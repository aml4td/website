library(readr)

# ------------------------------------------------------------------------------
# Food delivery data

load("RData/deliveries.RData")

write_csv(deliveries, file = "delimited/deliveries.csv")

