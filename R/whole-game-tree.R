library(rpart)
library(partykit)
library(tidymodels)
library(ggparty)
library(ggdark)

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

cart_party_tree <- as.party(cart_tree)

# ------------------------------------------------------------------------------

theme_transparent <- function(...) {
  
  ret <- ggplot2::theme_bw(...)
  
  transparent_rect <- ggplot2::element_rect(fill = "transparent", colour = NA)
  ret$panel.background  <- transparent_rect
  ret$plot.background   <- transparent_rect
  ret$legend.background <- transparent_rect
  ret$legend.key        <- transparent_rect
  
  ret$legend.position <- "top"
  
  ret
}

tree_light <- 
  cart_party_tree %>% 
  ggparty() +
  geom_edge() +
  geom_edge_label(size = 3.2) +
  geom_node_splitvar() +
  geom_node_plot(
    gglist = list(
      geom_boxplot(aes(y = time_to_delivery)),
      labs(x = NULL, y = NULL),
      lims(x = c(-1, 1)),
      theme_transparent(),
      theme(
        axis.ticks.x = element_blank(),
        axis.text.x = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_blank())
      )
    )


ggsave(
  filename = "premade/delivery-tree-light.svg",
  plot = tree_light,
  width = 9,
  height = 4.5,
  dev = "svg",
  bg = "transparent"
)

tree_dark <- 
  cart_party_tree %>% 
  ggparty() +
  geom_edge() +
  geom_edge_label(size = 3.2) +
  geom_node_splitvar() +
  geom_node_plot(
    gglist = list(
      geom_boxplot(aes(y = time_to_delivery)),
      labs(x = NULL, y = NULL),
      lims(x = c(-1, 1)),
      theme_transparent(),
      dark_theme_grey(),
      theme(
        axis.ticks.x = element_blank(),
        axis.text.x = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_blank())
    )
  )


ggsave(
  filename = "premade/delivery-tree-dark.svg",
  plot = tree_dark,
  width = 9,
  height = 4.5,
  dev = "svg",
  bg = "transparent"
)
