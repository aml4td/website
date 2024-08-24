library(tidyverse)
library(readxl)

ames_original <- 
  read_xls("../delimited/AmesHousing.xls", na=c("", "NA", NA),
           col_type = c(rep("guess", 73), "text", rep("guess", 8))) %>%
  mutate(Neighborhood = factor(Neighborhood)) %>%
  arrange(Neighborhood, Order)