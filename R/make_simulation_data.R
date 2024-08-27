library(tidyverse)

#Simulation_linear
set.seed(331)
linear_data <- 
  tibble(x1 = 8*runif(200) - 4,
         x2_act = x1 + 4,
         error = 1.5*rnorm(200),
         x2 = x2_act + error,
         prob = 1,
         true_class = ifelse(x2 > x2_act,1,-1),
         misclass_error = 1.5*runif(200),
         obs_class = ifelse(abs(error) < 1.5 - misclass_error,true_class*(-1),true_class),
         Observed = factor(ifelse(obs_class == -1, "Group1", "Group2"))) %>%
  mutate(relationship = "linear")


#Simulation_nonlinear
set.seed(331)
nonlinear_data <- 
  tibble(x1 = 8*runif(200) - 4,
         x2_act = (x1^2)/2 + 4,
         error = 1.5*rnorm(200),
         x2 = x2_act + error,
         prob = 1,
         true_class = ifelse(x2 > x2_act,1,-1),
         misclass_error = 1.5*runif(200),
         obs_class = ifelse(abs(error) < 1.5 - misclass_error,true_class*(-1),true_class),
         Observed = factor(ifelse(obs_class == -1, "Group1", "Group2"))) %>%
  mutate(relationship = "nonlinear")
  
simulation_data <-
  bind_rows(linear_data, nonlinear_data)

save(simulation_data, file="/Users/kjelljohnson/My Drive/Projects/APM/Missing Data/App/simulation_data.RData")