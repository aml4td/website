library(rpart)
library(partykit)
library(tidymodels)

# ------------------------------------------------------------------------------

light_bg <- "#fcfefe" # from aml4td.scss

# ------------------------------------------------------------------------------

load("RData/deliveries.RData")

set.seed(991)
delivery_split <- initial_validation_split(deliveries, prop = c(0.6, 0.2), strata = time_to_delivery)
delivery_train <- training(delivery_split)
delivery_test  <- testing(delivery_split)
delivery_val   <- validation(delivery_split)
delivery_rs    <- validation_set(delivery_split)

# ------------------------------------------------------------------------------

cart_tree <- 
  rpart(time_to_delivery ~ ., data = delivery_train,
        control = rpart.control(maxdepth = 3))

# ------------------------------------------------------------------------------

pdf("premade/delivery-tree.pdf", width = 12, height = 6)
  cart_tree %>% 
    as.party() %>% 
    plot()
dev.off()

# ------------------------------------------------------------------------------


svg("premade/delivery-tree.svg", width = 12, height = 6)
  grid.newpage()
  grid.rect(gp = gpar(col = light_bg, fill = light_bg))

  cart_tree %>% 
    as.party() %>% 
    plot(ip_args = list(id = FALSE, fill = light_bg),
         ep_args = list(fill = light_bg),
         tp_args = list(id = FALSE, bg = light_bg, fill = light_bg),
         newpage = FALSE)
dev.off()

