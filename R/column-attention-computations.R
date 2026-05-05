library(tidymodels)
library(torch)
library(patchwork)

# ------------------------------------------------------------------------------
# Module 1: Self-Attention Layer (Standard)

SelfAttention <- nn_module(
  "SelfAttention",
  
  initialize = function(n_features, embed_dim) {
    self$n_features <- n_features
    self$embed_dim <- embed_dim
    self$W_query <- nn_linear(1, embed_dim, bias = FALSE)
    self$W_key <- nn_linear(1, embed_dim, bias = FALSE)
    self$W_value <- nn_linear(1, embed_dim, bias = FALSE)
    self$W_out <- nn_linear(embed_dim, 1, bias = FALSE)
    self$scale <- sqrt(embed_dim)
    self$last_attention_weights <- NULL
  },
  
  forward = function(x) {
    # x: (batch_size, n_features)
    batch_size <- x$shape[1]
    n_features <- x$shape[2]
    
    # Reshape for per-feature projection
    x_expanded <- x$unsqueeze(3)
    
    # Compute queries, keys, values (one per feature)
    queries <- self$W_query(x_expanded)  # (batch, n_features, embed_dim)
    keys <- self$W_key(x_expanded)       # (batch, n_features, embed_dim)
    values <- self$W_value(x_expanded)   # (batch, n_features, embed_dim)
    
    # Compute attention scores: QK'
    scores <- torch_bmm(queries, keys$transpose(2, 3)) / self$scale
    
    # Apply softmax
    attn_weights <- nnf_softmax(scores, dim = 3)
    self$last_attention_weights <- attn_weights$detach()
    
    # Apply attention to values
    attended <- torch_bmm(attn_weights, values)
    
    # Project back to original space
    output <- self$W_out(attended)
    output <- output$squeeze(3)
    
    return(list(output = output, attention = attn_weights))
  }
)

# ------------------------------------------------------------------------------
# Module 2: Attention Binary Classifier Network

AttentionBinaryClassifier <- nn_module(
  "AttentionBinaryClassifier",
  
  initialize = function(n_features,
                        hidden_units_1 = 5L,
                        hidden_units_2 = 10L,
                        embed_dim = 8L) {
    
    self$fc1 <- nn_linear(n_features, hidden_units_1)
    self$bn1 <- nn_batch_norm1d(hidden_units_1)
    self$attention <- SelfAttention(hidden_units_1, embed_dim)
    self$fc2 <- nn_linear(hidden_units_1, hidden_units_2)
    self$fc3 <- nn_linear(hidden_units_2, 1L)
  },
  
  forward = function(x) {
    # First hidden layer
    x <- self$fc1(x)
    x <- nnf_relu(x)
    x <- self$bn1(x)
    
    # Apply self-attention
    attn_result <- self$attention(x)
    x <- attn_result$output
    attn_weights <- attn_result$attention
    
    # Second hidden layer
    x <- self$fc2(x)
    x <- nnf_relu(x)
    
    # Output logit
    logit <- self$fc3(x)
    
    return(list(logit = logit, attention = attn_weights))
  }
)

# ------------------------------------------------------------------------------
# Training Function

train_model <- function(model,
                        train_data,
                        val_data,
                        epochs = 100L,
                        batch_size = 16L,
                        learn_rate = 0.001,
                        penalty = 0.1,
                        stop_iter = 10L) {
  
  optimizer <- optim_adamw(model$parameters, lr = learn_rate, weight_decay = penalty)
  criterion <- nn_bce_with_logits_loss()
  
  # Create data loaders
  train_ds <- tensor_dataset(train_data$x, train_data$y)
  train_dl <- dataloader(train_ds, batch_size = batch_size, shuffle = TRUE)
  
  val_ds <- tensor_dataset(val_data$x, val_data$y)
  val_dl <- dataloader(val_ds, batch_size = batch_size, shuffle = FALSE)
  
  # Early stopping
  best_val_loss <- Inf
  stop_iter_counter <- 0L
  best_model_state <- NULL
  
  # Training history
  history <- list(
    train_loss = numeric(epochs),
    val_loss = numeric(epochs)
  )
  
  for (epoch in seq_len(epochs)) {
    # Training
    model$train()
    train_losses <- c()
    
    coro::loop(for (batch in train_dl) {
      optimizer$zero_grad()
      output <- model(batch[[1]])
      loss <- criterion(output$logit, batch[[2]])
      loss$backward()
      optimizer$step()
      train_losses <- c(train_losses, loss$item())
    })
    
    history$train_loss[epoch] <- mean(train_losses)
    
    # Validation
    model$eval()
    val_losses <- c()
    
    with_no_grad({
      coro::loop(for (batch in val_dl) {
        output <- model(batch[[1]])
        loss <- criterion(output$logit, batch[[2]])
        val_losses <- c(val_losses, loss$item())
      })
    })
    
    history$val_loss[epoch] <- mean(val_losses)
    
    # Early stopping
    if (history$val_loss[epoch] < best_val_loss) {
      best_val_loss <- history$val_loss[epoch]
      best_model_state <- model$state_dict()
      stop_iter_counter <- 0L
    } else {
      stop_iter_counter <- stop_iter_counter + 1L
      if (stop_iter_counter >= stop_iter) {
        break
      }
    }
  }
  
  # Restore best model
  model$load_state_dict(best_model_state)
  
  # Trim history
  actual_epochs <- epoch
  history$train_loss <- history$train_loss[1:actual_epochs]
  history$val_loss <- history$val_loss[1:actual_epochs]
  
  return(list(
    model = model,
    history = history,
    best_val_loss = best_val_loss
  ))
}

# ------------------------------------------------------------------------------
# Prediction Function

predict_prob <- function(model, x_tensor) {
  model$eval()
  with_no_grad({
    output <- model(x_tensor)
    probs <- torch_sigmoid(output$logit)
    list(
      probabilities = probs$detach()$cpu(),
      attention = output$attention$detach()$cpu()
    )
  })
}


# ------------------------------------------------------------------------------
# Other functions

compute_attention <- function(model, A, B) {
  model$eval()
  
  # Create input tensor
  x <- torch_tensor(matrix(c(A, B), nrow = 1), dtype = torch_float())
  
  with_no_grad({
    # -------------------------------------------------------------------------
    # Step 1: First linear layer
    h_linear <- model$fc1(x)  # (1, n_hidden)
    h_linear_vec <- as.numeric(h_linear$cpu())
    
    # -------------------------------------------------------------------------
    # Step 2: ReLU activation
    
    h_relu <- nnf_relu(h_linear)
    h_relu_vec <- as.numeric(h_relu$cpu())
    
    # -------------------------------------------------------------------------
    # Step 3: Batch normalization (IMPORTANT!)
    # -------------------------------------------------------------------------
    h_bn <- model$bn1(h_relu)
    h_bn_vec <- as.numeric(h_bn$cpu())
    
    # This is what attention actually sees
    # (Note: BatchNorm uses running statistics in eval mode)
    
    # -------------------------------------------------------------------------
    # Step 4: Self-attention computation
    
    # The attention layer does:
    # 1. Projects h_bn to queries, keys, values
    # 2. Computes attention weights: softmax(QK' / sqrt(d))
    # 3. Applies attention to values: attention at V
    # 4. Projects back to hidden space
    
    attn_result <- model$attention(h_bn)
    attended_output <- attn_result$output
    attention_weights <- attn_result$attention
    
    attended_vec <- as.numeric(attended_output$cpu())
    attn_matrix <- as.matrix(attention_weights[1, , ]$cpu())
  })
  
  attended_mat <- t(as.matrix(attended_vec))
  colnames(attended_mat) <- recipes::names0(ncol(attended_mat), "hidden unit ")
  attended <- as_tibble(attended_mat)
  attended$A <- A
  attended$B <- B
  attended$type <- "Attended"
  
  before <- h_bn_vec
  names(before) <- recipes::names0(length(h_bn_vec), "hidden unit ")
  before <- tibble::as_tibble_row(before)
  before$A <- A
  before$B <- B
  before$type <- "Unattended"
  bind_rows(before, attended)
}

# Prepare data
convert_tensor <- function(x) {
  y <- torch_tensor(ifelse(x$class == levels(x$class)[1], 1, 0), dtype = torch_float())
  y <- y$unsqueeze(2)
  x <- torch_tensor(as.matrix(x[, 1:2]), dtype = torch_float())
  list(x = x, y = y)
}


att_format <- function(model, x, tibble = FALSE) {
  # Ensure x is a float32 tensor (not float64)
  if (!inherits(x, "torch_tensor")) {
    x <- torch_tensor(x, dtype = torch_float())
  }
  
  preds <- predict_prob(model, x)
  test_preds <- (preds$probabilities > 0.5)$to(dtype = torch_float())
  
  attn_matrix <- as.matrix(preds$attention[1, , ])
  colnames(attn_matrix) <- rownames(attn_matrix) <- recipes::names0(ncol(attn_matrix), "hidden unit ")
  if (tibble) {
    attn_matrix <-
      as_tibble(attn_matrix, rownames = "row") |>
      pivot_longer(cols = c(-row), names_to = "col")
  }
  attn_matrix
}

# ------------------------------------------------------------------------------
# Example: Train on sim_logistic Data

load("../RData/dat_2d.RData")

train_data <- convert_tensor(dat_2d_train)
val_data <- convert_tensor(dat_2d_val)

x_seq <- seq(-3, 3, length.out = 50)
grid <- expand.grid(A = x_seq, B = x_seq)
grid_tens <- torch_tensor(as.matrix(grid), dtype = torch_float())

# Create model
torch_manual_seed(711)
model <- AttentionBinaryClassifier(
  n_features = 2,
  hidden_units_1 = 4L,
  hidden_units_2 = 10L,
  embed_dim = 6L
)

col_att_model <- train_model(
  model = model,
  train_data = train_data,
  val_data = val_data,
  epochs = 100L,
  batch_size = 16L,
  learn_rate = 0.01,
  penalty = 0.01, 
  stop_iter = 5L
)

# ------------------------------------------------------------------------------

coefs <- col_att_model$model$parameters
wt_1 <- format(as.matrix(coefs$fc1.weight), digits = 1)
wt_1 <- gsub("^ ", "+", wt_1)
wt_1[,1] <- paste0(wt_1[,1], "\\:A")
wt_1[,2] <- paste0(wt_1[,2], "\\:B")
lp_1 <- 
  cbind(
    format(as.matrix(coefs$fc1.bias), digits = 2),
    wt_1
  )
lp_1 <- apply(lp_1, 1, function(x) paste0(x, collapse = ""))
lp_1 <- paste0("H_{", 1:4, "}&=", lp_1, " \\notag")

cat("$$")
cat("\\begin{align}")
cat(paste0(lp_1, collapse = " \\\\ \n"))
cat("\\end{align}")
cat("$$")

# ------------------------------------------------------------------------------

new_mat <- matrix(c(2, 1/2, 0, 1.25, -2, -2), ncol = 2, byrow = TRUE)
colnames(new_mat) <- LETTERS[1:2]
new_df <- as_tibble(new_mat) |> mutate(label = paste(1:3))
new_tens <- torch_tensor(new_mat, dtype = torch_float())

grid_pred <- 
  col_att_model$model |> 
  predict_prob(grid_tens) |> 
  pluck("probabilities") |> 
  as.matrix() |> 
  as_tibble() |> 
  set_names(".pred_1")

plot_grid <- 
  grid |> 
  bind_cols(grid_pred)

plot_grid |> 
  ggplot(aes(A, B)) + 
  geom_point(data = dat_2d_train, aes(col = class), alpha = 2/3) +
  geom_point(data = new_df, size = 4, shape = 21, fill = "white", color = "black") + 
  geom_text(data = new_df, aes(label = label), size = 2) +
  geom_contour(aes(z = .pred_1), breaks = 1/2, col = "black") +
  coord_obs_pred() + 
  theme_bw() + 
  scale_color_manual(values = c("#007FFFFF", "#FF7F00FF"))

# ------------------------------------------------------------------------------

att_format(col_att_model$model, new_mat[1,, drop = FALSE]) |> 
  round(2) |> 
  knitr::kable()

att_format(col_att_model$model, new_mat[2,, drop = FALSE]) |> 
  round(2) |> 
  knitr::kable()

att_format(col_att_model$model, new_mat[3,, drop = FALSE]) |> 
  round(2) |> 
  knitr::kable()

# ------------------------------------------------------------------------------

# bind_rows(
#   att_format(col_att_model$model, new_mat[1,, drop = FALSE], tibble = TRUE) |> mutate(Sample = "Location 1"),
#   att_format(col_att_model$model, new_mat[2,, drop = FALSE], tibble = TRUE) |> mutate(Sample = "Location 2"),
#   att_format(col_att_model$model, new_mat[3,, drop = FALSE], tibble = TRUE) |> mutate(Sample = "Location 3")
# ) |> 
#   ggplot(aes(col, forcats::fct_rev(row))) + 
#   geom_tile(aes(fill = value)) + 
#   facet_wrap(~ Sample) +
#   scale_fill_gradient(low = "white", high = "#771434FF", limits = c(0, 1)) +
#   scale_y_discrete(labels = c(expression(H[3]), expression(H[2]), expression(H[1]))) +
#   scale_x_discrete(labels = c(expression(H[1]), expression(H[2]), expression(H[3]))) +
#   labs(x = NULL, y = NULL, fill = "Attention\nWeight")

# ------------------------------------------------------------------------------


loc_tbl <- NULL
for (i in 1:3) {
  tmp_loc <- att_format(col_att_model$model, new_mat[i,, drop = FALSE])
  colnames(tmp_loc) <- (paste0("loc_", i, "_unit", 1:4)) 
  tmp_loc <- as_tibble(tmp_loc)
  if (i == 1) {
    tmp_loc <- tmp_loc |> mutate(Feature = recipes::names0(4, "Hidden Unit ")) |> 
      relocate(Feature)
  }
  loc_tbl <- bind_cols(loc_tbl, tmp_loc)
}

library(gt)
loc_tbl |> 
  mutate(Feature = paste0("$$H_", 1:4, "$$")) |> 
  gt() |> 
  cols_add('spacr1' = '', .after = 'Feature') |>
  cols_add('spacr2' = '', .after = 5) |>
  cols_add('spacr3' = '', .after = 'loc_2_unit4') |>
  cols_label('spacr1' = md('&emsp;&emsp;'),
             'spacr2' = md('&emsp;&emsp;'),
             'spacr3' = md('&emsp;&emsp;')) |>
  fmt_markdown(columns = Feature) |> 
  fmt_number(columns = c(-Feature), decimals = 2) |> 
  cols_label(
    contains("unit1") ~ md("$H_1$"),
    contains("unit2") ~ md("$H_2$"),
    contains("unit3") ~ md("$H_3$"),
    contains("unit4") ~ md("$H_4$"),
  ) |> 
  # tab_spanner(label = "Attended By", columns = c(contains("loc_")), level = 1) |>
  tab_spanner(label = "Location 1", columns = c(contains("loc_1"))) |>
  tab_spanner(label = "Location 2", columns = c(contains("loc_2"))) |>
  tab_spanner(label = "Location 3", columns = c(contains("loc_3")))  |>
  tab_style_body(style = cell_text(color = "gray70"), fn = function(x) is.numeric(x) & x < 0.01)



# ------------------------------------------------------------------------------

att_grid <- before_after_grid <- NULL

for (i in 1:nrow(grid_tens)) {
  tmp <- 
    att_format(col_att_model$model, grid_tens[i,, drop = FALSE], tibble = TRUE) |> 
    mutate(A = grid$A[i], B = grid$B[i])
  att_grid <- bind_rows(att_grid, tmp)
  
  tmp_ba <- compute_attention(col_att_model$model, A = grid$A[i], B = grid$B[i])
  before_after_grid <- bind_rows(before_after_grid, tmp_ba)
}

att_grid |> 
  ggplot(aes(A, B)) + 
  geom_tile(aes(fill = value), alpha = 3 / 4) + 
  geom_contour(data = plot_grid, aes(z = .pred_1), breaks = 1/2, col = "black", linewidth = 1) +
  geom_point(data = new_df, size = 4, shape = 21, fill = "white", color = "black") + 
  geom_text(data = new_df, aes(label = label), size = 2) +
  facet_grid(row ~ col,  switch = "y") +
  scale_fill_gradient(low = "white", high = "#771434FF", limits = c(0, 1))+
  labs(fill = "Attention\nWeight") +
  theme_bw()


p_before <- 
  before_after_grid |> 
  pivot_longer(cols = c(contains("hidden")), names_to = "unit") |> 
  filter(type == "Unattended") |> 
  ggplot(aes(A, B)) + 
  geom_tile(aes(fill = value), show.legend = TRUE) + 
  geom_contour(aes(z = value), breaks = 0, col = "black") +
  facet_wrap(~ unit, nrow = 1) + 
  scale_fill_gradient2(high = "#5D74A5FF") + 
  coord_fixed() +
  theme_bw() + 
  theme(
    legend.position = "right",
    plot.title = element_text(hjust = 0.5),
    legend.title = element_blank()
  ) + 
  labs(title = "Unattended") 

p_after <- 
  before_after_grid |> 
  pivot_longer(cols = c(contains("hidden")), names_to = "unit") |> 
  filter(type == "Attended") |> 
  ggplot(aes(A, B)) + 
  geom_tile(aes(fill = value), show.legend = TRUE) + 
  geom_contour(aes(z = value), breaks = 0, col = "black") +
  facet_wrap(~ unit, nrow = 1) + 
  scale_fill_gradient2(high = "#5D74A5FF") + 
  coord_fixed() +
  theme_bw() + 
  theme(
    legend.position = "right",
    plot.title = element_text(hjust = 0.5),
    legend.title = element_blank()
  ) + 
  labs(title = "Attended") 

p_before / p_after
