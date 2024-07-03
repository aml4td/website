library(rpart)
library(partykit)
library(animation)
library(tidymodels)
library(patchwork)
library(ggdark)

# ------------------------------------------------------------------------------

source("R/_common.R")

tidymodels_prefer()
theme_set(theme_transparent())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)

# ------------------------------------------------------------------------------

source("R/setup_hotel_rates.R")

agent_stats <-
  hotel_rate_train %>%
  group_by(agent) %>%
  summarize(
    mean = mean(avg_price_per_room),
    `# bookings` = n(),
    .groups = "drop"
  ) 

# ------------------------------------------------------------------------------

ctrl <- rpart.control(maxdepth = 5, minsplit = 5, cp = 1e-04)
rpart_mod <- rpart(avg_price_per_room ~ agent, data = hotel_rate_train, control = ctrl)
split_data <- 
  rpart_mod$cptable %>% 
  as_tibble() %>% 
  filter(nsplit > 0) %>% 
  mutate(groups = nsplit + 1)

get_node <- function(x) {
  rpart_mod_pty <- as.party(x)
  nodes <- predict(rpart_mod_pty, hotel_rate_train[, "agent"], type = "node")
  tmp <- hotel_rate_train %>% select(agent)
  tmp$node <- unname(nodes)
  
  groups <- 
    tmp %>% 
    distinct(node) %>% 
    arrange(node) %>% 
    mutate(group = row_number()) %>% 
    full_join(tmp, by = "node") %>% 
    inner_join(agent_stats, by = "agent") %>% 
    mutate(
      label = format(group),
      agent_ordered = reorder(agent, mean),
      agent_index = as.numeric(agent_ordered)
    )
  groups
}

# ------------------------------------------------------------------------------

saveGIF({
  for(i in 1:nrow(split_data)) {
    
    tmp_mod <- rpart::prune(rpart_mod, cp = split_data$CP[i])
    
    rpart_mod_pty <- as.party(tmp_mod)
    predict(rpart_mod_pty, hotel_rate_train[, "agent"], type = "node")
    
    eps <- 1 / 500
    cut_data <- 
      get_node(tmp_mod) %>% 
      summarize(
        min = min(agent_index),
        max = max(agent_index),  
        .by = label
      )
    cut_vals <- cut_data$min[-which.min(cut_data$min)]
    
    p_data <- 
      get_node(tmp_mod) %>% 
      ggplot(aes(agent_index, mean, col = label)) + 
      geom_point(cex = 1, alpha = 1 / 3, show.legend = FALSE) +
      geom_vline(xintercept = cut_vals, lty = 2) +
      labs(y = "Mean ADR", x = "Agent (index)") 
    
    p_progress <- 
      split_data %>% 
      slice(1:i) %>% 
      ggplot(aes(groups, xerror)) + 
      geom_point() +
      scale_x_continuous(breaks = pretty_breaks(), limits = range(split_data$groups)) + 
      ylim(extendrange(split_data$xerror)) +
      labs(x = "Number of Groups", y = "Error")
    
    if (i > 1) {
      p_progress <- p_progress + geom_line()
    }
    
    print( p_data / p_progress +  plot_layout(heights = c(2, 1)) ) 
  }
},
movie.name = "anime-tree-collapse-light.gif",
interval = 1,
nmax = 50,
ani.width = 600 * 2,
ani.height = 600 * 2,
ani.res = 96 * 2
)

# ------------------------------------------------------------------------------


ggplot2::reset_theme_settings()
ggplot2::theme_set(theme_transparent())
ggplot2::theme_set(ggdark::dark_theme_grey())

saveGIF({
  for(i in 1:nrow(split_data)) {
    
    tmp_mod <- rpart::prune(rpart_mod, cp = split_data$CP[i])
    
    rpart_mod_pty <- as.party(tmp_mod)
    predict(rpart_mod_pty, hotel_rate_train[, "agent"], type = "node")
    
    eps <- 1 / 500
    cut_data <- 
      get_node(tmp_mod) %>% 
      summarize(
        min = min(agent_index),
        max = max(agent_index),  
        .by = label
      )
    cut_vals <- cut_data$min[-which.min(cut_data$min)]
    
    p_data <- 
      get_node(tmp_mod) %>% 
      ggplot(aes(agent_index, mean, col = label)) + 
      geom_point(cex = 1, alpha = 1 / 3, show.legend = FALSE) +
      geom_vline(xintercept = cut_vals, lty = 2) +
      labs(y = "Mean ADR", x = "Agent (index)") 
    
    p_progress <- 
      split_data %>% 
      slice(1:i) %>% 
      ggplot(aes(groups, xerror)) + 
      geom_point() +
      scale_x_continuous(breaks = pretty_breaks(), limits = range(split_data$groups)) + 
      ylim(extendrange(split_data$xerror)) +
      labs(x = "Number of Groups", y = "Error")
    
    if (i > 1) {
      p_progress <- p_progress + geom_line()
    }
    
    print( p_data / p_progress +  plot_layout(heights = c(2, 1)) ) 
  }
},
movie.name = "anime-tree-collapse-dark.gif",
interval = 1,
bg = "black",
nmax = 50,
ani.width = 600 * 2,
ani.height = 600 * 2,
ani.res = 96 * 2
)


