# =============================================================================
# Column-attention MLP demo (R + torch)
# =============================================================================
#
# A small pedagogical example for a book chapter on column attention.
#
# The model is:
#
#   x = (A, B)
#     -> nn_linear(2, 4) -> ReLU                          (hidden state h)
#     -> column_attention(n_columns = 4, embedding_dim = m)
#     -> flatten attended embeddings (4 * m)
#     -> nn_linear(4 * m, 1)                              (logit)
#
# The column-attention block expands each scalar hidden unit h[j] into an
# m-dimensional embedding e_j, then runs standard self-attention over the 4
# "column tokens". It returns:
#
#   attn : (B, 4, 4)     -- one 4x4 attention weight matrix per sample
#   z    : (B, 4, m)     -- one 4xm matrix of attended embeddings per sample
#
# Both are saved on a dense grid over the (A, B) plane so the chapter can
# visualize how attention varies across input space.
#
# The script is over-commented intentionally for a non-torch R audience.
# Every torch operation has a brief explanation, and every tensor assignment
# carries a shape comment. We use B for batch size throughout (avoiding N
# which usually means "row count" in tidy contexts).

# ---- 1. Setup ---------------------------------------------------------------

library(torch)
library(cli)
library(tidymodels)
library(brulee)

# RNG seeds (R's own AND torch's) are set later, JUST BEFORE model
# construction + training, so model init and mini-batch shuffling are both
# reproducible from a single place.

# Load the dataset. The .RData file puts two data frames into the global env:
#   dat_2d_train (1000 rows)
#   dat_2d_val   (100  rows)
# Each has columns:
#   A     numeric
#   B     numeric
#   class factor with two levels: "one", "two"
load("~/content/website/RData/dat_2d.RData")

# Convert a data frame to a list of (x, y) torch tensors.
#
#   x : (B, 2) float tensor with columns A, B in that order.
#   y : (B, 1) float tensor of 0/1 targets.
#
# Mapping: we send the SECOND factor level to 1 (positive class). With
# levels = c("one", "two") that means "two" -> 1, "one" -> 0. The first call
# prints the mapping so the chapter shows it explicitly.
#
# y must be float (not integer/long) because nnf_binary_cross_entropy_with_logits
# expects a float target tensor.
to_tensors <- function(df, announce_levels = FALSE) {
  lev <- levels(df$class)
  if (announce_levels) {
    cli::cli_inform("Factor mapping: 0 <- {.val {lev[1]}}, 1 <- {.val {lev[2]}}")
  }
  # as.integer(<logical>) gives 0/1; matrix(..., ncol = 1) keeps the (B, 1)
  # column-vector shape that torch's BCE loss wants to see.
  y_mat <- matrix(as.integer(df$class == lev[2]), ncol = 1)
  list(
    x = torch_tensor(as.matrix(df[, c("A", "B")]), dtype = torch_float()),
    y = torch_tensor(y_mat,                       dtype = torch_float())
  )
}

train_data <- to_tensors(dat_2d_train, announce_levels = TRUE)
val_data   <- to_tensors(dat_2d_val)

# Print the resulting tensor shapes so the reader sees them concretely.
# $shape on a torch_tensor returns an integer vector, like dim() in base R.
cli::cli_inform("train x shape: {paste(train_data$x$shape, collapse = ' x ')}")
cli::cli_inform("train y shape: {paste(train_data$y$shape, collapse = ' x ')}")


# ---- 2. The column-attention block ------------------------------------------

# column_attention is an nn_module. nn_module() returns a "generator" -- you
# call it like a function to create an instance, similar to an R6 class.
#
# Inputs to forward():
#   h : (B, n_columns) float tensor -- the hidden state from the MLP.
#
# Outputs (a list):
#   attn : (B, n_columns, n_columns)     attention weights, last-dim rows sum to 1
#   z    : (B, n_columns, embedding_dim) attended embeddings
#
# Internally:
#   1. Expand each scalar hidden unit h[b, j] into an m-dim embedding
#         e_j = tanh(h[b, j] * w_j + b_j)
#      with per-column w_j, b_j learned. Stack -> E of shape (B, n_columns, m).
#      The tanh nonlinearity is important: without it every row of E is just
#      a scalar multiple of (w_j, b_j), and Q/K/V projections become degenerate
#      within a column.
#   2. Project E to queries, keys, values with three SHARED linear maps
#      (the same W_Q is applied to all 4 columns).
#   3. Compute attention scores Q K^T / sqrt(m); softmax over keys.
#   4. Attended values z = attn %*% V.

column_attention <- nn_module(
  "column_attention",

  initialize = function(n_columns = 4L, embedding_dim = 4L) {
    self$n_columns     <- n_columns
    self$embedding_dim <- embedding_dim

    # Per-column embedding parameters. nn_parameter() wraps a tensor so torch
    # registers it as a learnable parameter (it shows up in model$parameters
    # and is updated by the optimizer).
    #
    # Shapes: (n_columns, m). We initialise with small random values, NOT
    # zeros: zero init would make Q/K/V identical across columns at step 0,
    # symmetry the optimizer can't break.
    self$embed_w <- nn_parameter(torch_randn(n_columns, embedding_dim) * 0.1)
    self$embed_b <- nn_parameter(torch_randn(n_columns, embedding_dim) * 0.1)

    # The three QKV projections. Shared across the n_columns tokens (the same
    # W_Q is applied to every column's embedding).
    # bias = FALSE is conventional for QKV layers in attention.
    self$W_Q <- nn_linear(embedding_dim, embedding_dim, bias = FALSE)
    self$W_K <- nn_linear(embedding_dim, embedding_dim, bias = FALSE)
    self$W_V <- nn_linear(embedding_dim, embedding_dim, bias = FALSE)
  },

  forward = function(h) {
    # h : (B, n_columns)                  -- one row per sample
    #
    # Goal: build E of shape (B, n_columns, m) where each row j is the
    # m-dim embedding of the scalar h[b, j]. We use broadcasting:
    #
    #   h$unsqueeze(-1) : (B, n_columns, 1)    -- add a trailing axis
    #   self$embed_w    :    (n_columns, m)    -- broadcasts as (1, n_columns, m)
    #   product         : (B, n_columns, m)
    #
    # unsqueeze(-1) inserts a size-1 dim at the last position. This is how you
    # line up axes for broadcasting in torch (no recycling rules like base R).
    h_un  <- h$unsqueeze(-1)                          # (B, n_columns, 1)
    E_pre <- h_un * self$embed_w + self$embed_b       # (B, n_columns, m)

    # Squash to (-1, 1). Adds nonlinearity at zero parameter cost and breaks
    # the rank-1-in-h degeneracy of the raw affine map.
    E <- torch_tanh(E_pre)                            # (B, n_columns, m)

    # nn_linear acts on the LAST dim of its input. Feeding a (B, n_columns, m)
    # tensor returns a (B, n_columns, m) tensor (m -> m projection per row).
    Q <- self$W_Q(E)                                  # (B, n_columns, m)
    K <- self$W_K(E)                                  # (B, n_columns, m)
    V <- self$W_V(E)                                  # (B, n_columns, m)

    # Attention scores Q K^T. We transpose the LAST two axes of K -- NOT the
    # batch axis. In R-torch, dimensions are 1-based, so for a 3-D tensor the
    # last two dims are 2 and 3.
    #
    #   Q                   : (B, n_columns, m)
    #   K$transpose(2, 3)   : (B, m, n_columns)
    #   torch_matmul(Q, .)  : (B, n_columns, n_columns)
    #
    # torch_matmul broadcasts the batch dim implicitly when both inputs are
    # 3-D. The result holds one (n_columns x n_columns) score matrix per sample.
    #
    # We divide by sqrt(m) so the score variance stays roughly O(1) regardless
    # of embedding size (standard scaled dot-product attention).
    scores <- torch_matmul(Q, K$transpose(2, 3)) / sqrt(self$embedding_dim)
    # scores : (B, n_columns, n_columns)

    # Softmax along the LAST dim. dim = -1 means "last axis"; for our
    # (B, n_columns, n_columns) tensor that's the keys axis, so every row of
    # the resulting per-sample matrix sums to 1.
    attn <- nnf_softmax(scores, dim = -1)             # (B, n_columns, n_columns)

    # Attended values: matmul (B, 4, 4) %*% (B, 4, m) -> (B, 4, m).
    z <- torch_matmul(attn, V)                        # (B, n_columns, m)

    list(attn = attn, z = z)
  }
)


# ---- 3. The full MLP + attention model --------------------------------------

# mlp_with_attention chains everything end-to-end:
#
#   x (B, 2)
#     -> fc1 (B, 4)
#     -> ReLU
#     -> column_attention -> list(attn (B,4,4), z (B,4,m))
#     -> flatten z to (B, 4*m)
#     -> fc_out -> logit (B, 1)
#
# forward() returns a list with logit, attn, z so callers can pull all three
# (the loss only needs logit; the grid extraction needs attn and z too).

mlp_with_attention <- nn_module(
  "mlp_with_attention",

  initialize = function(n_features    = 2L,
                        n_hidden      = 4L,
                        embedding_dim = 4L) {
    self$n_hidden      <- n_hidden
    self$embedding_dim <- embedding_dim

    self$fc1        <- nn_linear(n_features, n_hidden)
    self$attn_block <- column_attention(
      n_columns     = n_hidden,
      embedding_dim = embedding_dim
    )
    # The attention block returns z of shape (B, n_hidden, m). We flatten to
    # (B, n_hidden * m) before the final linear layer.
    self$fc_out <- nn_linear(n_hidden * embedding_dim, 1L)
  },

  forward = function(x) {
    # x : (B, 2)
    h_lin <- self$fc1(x)                              # (B, 4)
    h     <- nnf_relu(h_lin)                          # (B, 4)
    out   <- self$attn_block(h)                       # list: attn, z

    # Flatten (B, 4, m) -> (B, 4 * m).
    #   reshape(c(B, -1L)) means "keep dim 1 as B, infer the rest".
    # We have to read B off the input tensor since it varies between training
    # batches and the grid forward pass.
    B      <- x$shape[1]
    z_flat <- out$z$reshape(c(B, -1L))                # (B, 4 * m)

    logit <- self$fc_out(z_flat)                      # (B, 1)
    list(logit = logit, attn = out$attn, z = out$z)
  }
)


# ---- 4. Training ------------------------------------------------------------

# -- 4a. Hyperparameters ------------------------------------------------------
#
# All knobs in one place, just before the model is constructed. Tweak here,
# not deeper in the loop.
n_hidden      <- 4L     # number of hidden units = number of column tokens
                        # (the attention matrix is n_hidden x n_hidden)
embedding_dim <- 2L     # m: width of each column embedding
n_epochs      <- 500L   # max passes over the training set
batch_size    <- 64L    # mini-batch size; the loader reshuffles each epoch
learn_rate    <- 0.01   # Adam step size
weight_decay  <- 0.01   # L2 regularization, applied via AdamW
stop_iter     <- 20L    # early-stopping patience (epochs without val improvement)
seed <- 439

# -- 4b. Seeds, model, optimizer, dataloader ----------------------------------

# Set both RNGs JUST BEFORE model construction + training. This makes
#   (a) model parameter initialization (torch_randn inside nn_parameter)
#   (b) the per-epoch mini-batch shuffle order (R-level sample())
# both reproducible, from a single place.
set.seed(seed)
torch_manual_seed(seed)

model <- mlp_with_attention(
  n_features    = 2L,
  n_hidden      = n_hidden,
  embedding_dim = embedding_dim
)

# optim_adamw applies *decoupled* weight decay -- the modern, recommended
# L2 variant for Adam. The vanilla optim_adam's `weight_decay` arg couples
# decay into the gradient, which interacts badly with Adam's adaptive
# per-parameter learning rates.
optimizer <- optim_adamw(
  model$parameters,
  lr           = learn_rate,
  weight_decay = weight_decay
)

# Build a streaming mini-batch dataloader over the training tensors.
# tensor_dataset() pairs x and y so each yielded batch is a list of two
# tensors: batch[[1]] = x_batch, batch[[2]] = y_batch.
# shuffle = TRUE reshuffles row order every epoch (uses R-level RNG -- the
# reason we set.seed() above).
train_ds <- tensor_dataset(train_data$x, train_data$y)
train_dl <- dataloader(train_ds, batch_size = batch_size, shuffle = TRUE)


# -- 4c. Training loop with early stopping ------------------------------------
#
# After each epoch we evaluate val loss. If it improves we snapshot the
# weights; if it fails to improve for `stop_iter` consecutive epochs we stop
# and rewind the model to the best snapshot.

best_val_loss <- Inf
best_epoch    <- 0L
best_state    <- NULL
stop_counter  <- 0L

all_val_loss <- rep(NA_real_, n_epochs)

for (epoch in seq_len(n_epochs)) {
  model$train()                  # train mode; no-op here (no dropout/BN) but
                                 # idiomatic and a habit worth showing.

  # Accumulate per-batch loss values for a clean epoch-mean train loss.
  batch_losses <- numeric(0)

  # coro::loop iterates over the dataloader's coroutine. Each `batch` is
  # the list yielded by the dataset: batch[[1]] = x, batch[[2]] = y.
  coro::loop(for (batch in train_dl) {
    optimizer$zero_grad()                              # clear .grad from previous step
    out  <- model(batch[[1]])
    loss <- nnf_binary_cross_entropy_with_logits(out$logit, batch[[2]])
    loss$backward()                                    # accumulate .grad
    optimizer$step()                                   # apply AdamW update
    batch_losses <- c(batch_losses, loss$item())
  })

  train_loss <- mean(batch_losses)

  # Validation forward pass on the full val tensor (only 100 rows; no need to
  # batch). with_no_grad() skips autograd graph construction -- faster and
  # cheaper when we just want predictions.
  model$eval()
  with_no_grad({
    val_out  <- model(val_data$x)
    val_loss <- nnf_binary_cross_entropy_with_logits(
      val_out$logit, val_data$y
    )$item()
  })

  all_val_loss[epoch] <- val_loss

  # Did val loss improve? If so, snapshot the weights.
  # We CLONE every tensor returned by state_dict(): the entries can be live
  # references to the model's parameters, so without $clone() the saved
  # snapshot would silently track subsequent updates.
  if (val_loss < best_val_loss) {
    best_val_loss <- val_loss
    best_epoch    <- epoch
    best_state    <- lapply(model$state_dict(), function(t) t$clone())
    stop_counter  <- 0L
  } else {
    stop_counter <- stop_counter + 1L
  }

  if (epoch == 1L || epoch %% 50L == 0L) {
    cli::cli_inform(sprintf(
      "epoch %3d | train loss %.3f | val loss %.3f | best %.3f @ epoch %d",
      epoch, train_loss, val_loss, best_val_loss, best_epoch
    ))
  }

  if (stop_counter >= stop_iter) {
    cli::cli_alert_info(
      "Early stopping at epoch {epoch}: no val improvement for {stop_iter} epochs."
    )
    break
  }
}

# Rewind to the lowest-val-loss epoch.
if (!is.null(best_state)) {
  model$load_state_dict(best_state)
  cli::cli_alert_success(
    "Restored weights from epoch {best_epoch} (val loss {sprintf('%.3f', best_val_loss)})."
  )
}

all_val_loss <- all_val_loss[!is.na(all_val_loss)]
all_val_loss <- tibble(loss = all_val_loss, iter = seq_along(all_val_loss))
p_val <-
 ggplot(all_val_loss, aes(iter, loss)) +
 geom_point() +
 theme_bw()
print(p_val)

# ---- 5. Final evaluation ----------------------------------------------------

model$eval()
with_no_grad({
  val_out  <- model(val_data$x)
  val_loss <- nnf_binary_cross_entropy_with_logits(val_out$logit, val_data$y)$item()
})
cli::cli_alert_info("Final val loss: {sprintf('%.3f', val_loss)}")


# ---- 6. Grid extraction for visualization -----------------------------------

# Evaluate the model on a dense (A, B) grid so the chapter can plot how the
# attention weights and attended embeddings vary across input space.

grid_n <- 50L
grid <- expand.grid(
  A = seq(-3, 3, length.out = grid_n),
  B = seq(-3, 3, length.out = grid_n)
) |> 
  as_tibble()

three_locations <- matrix(c(2, 1 / 2, 0, 1.25, -2, -2), ncol = 2, byrow = TRUE)
colnames(three_locations) <- LETTERS[1:2]
location_df <- as_tibble(three_locations) 
grid <- bind_rows(location_df, grid)

# Convert to a (G, 2) float tensor where G = grid_n^2.
x_grid <- torch_tensor(as.matrix(grid), dtype = torch_float())   # (G, 2)

model$eval()
with_no_grad({
  out <- model(x_grid)

  # Pull tensors back to R:
  #   $detach() drops the tensor from the autograd graph (already a no-op
  #             here because of with_no_grad(), but explicit is safer).
  #   $cpu()    moves to CPU (no-op on a CPU-only setup).
  # as.numeric() on a torch_tensor flattens it to an R numeric vector.
  logit_vec <- as.numeric(out$logit$detach()$cpu())                # length G
  prob_vec  <- as.numeric(torch_sigmoid(out$logit)$detach()$cpu()) # length G

  # as.array() on a 3-D torch_tensor returns a 3-D R array with matching dims.
  attn_arr <- as.array(out$attn$detach()$cpu())              # (G, n_hidden, n_hidden)
  z_arr    <- as.array(out$z$detach()$cpu())                 # (G, n_hidden, m)
})

# Build a wide tidy data frame:
#   A, B, logit, prob,
#   attn_j_k for j, k in 1..n_hidden   (n_hidden^2 cols; rows sum to 1),
#   z_j_k    for j in 1..n_hidden, k in 1..m   (n_hidden*m cols).
col_att_grid <- data.frame(
  A     = grid$A,
  B     = grid$B,
  logit = logit_vec,
  prob  = prob_vec
)

for (j in seq_len(n_hidden)) {
  for (k in seq_len(n_hidden)) {
    col_att_grid[[paste0("attn_", j, "_", k)]] <- attn_arr[, j, k]
  }
}
for (j in seq_len(n_hidden)) {
  for (k in seq_len(embedding_dim)) {
    col_att_grid[[paste0("z_", j, "_", k)]] <- z_arr[, j, k]
  }
}

# Sanity check: for every grid point, the keys-axis sums to 1 (per query row j).
# apply(<3D array>, c(1, 2), sum) collapses the LAST axis -- the keys -- giving
# a (G x n_hidden) matrix of row sums that should all equal 1.
attn_row_sums <- apply(attn_arr, c(1, 2), sum)              # (G, n_hidden)
stopifnot(all(abs(attn_row_sums - 1) < 1e-5))

# set.seed(123)
# mlp_fit <- brulee_mlp(
#  class ~ A + B,
#  data = dat_2d_train,
#  hidden_units = 4,
#  penalty = 0,
#  learn_rate = 0.001,
#  activation = "relu",
#  optimizer = "ADAMw",
#  batch_size = 16L,
# )
# col_att_grid$mlp <- predict(mlp_fit, col_att_grid[, c("A", "B")], type = "prob")[[1]]


# p_contour <-
#  col_att_grid |>
#  ggplot(aes(A, B)) +
#  geom_point(data = dat_2d_train, aes(col = class), alpha = 2 / 3) +
#  # geom_point(
#  #  data = location_df,
#  #  size = 4,
#  #  shape = 21,
#  #  fill = "white",
#  #  color = "black"
#  # ) +
#  # geom_text(data = location_df, aes(label = label), size = 2) +
#  # geom_contour(aes(z = mlp), breaks = 1 / 2, col = "black", alpha = 1 / 4) +
#  geom_contour(aes(z = prob), breaks = 1 / 2, col = "black") +
#  coord_obs_pred() +
#  theme_bw() +
#  scale_color_manual(values = c("#007FFFFF", "#FF7F00FF"))
# print(p_contour)

# ------------------------------------------------------------------------------
# 7 plots over predictor space

# 
# p_att <-
#  col_att_grid |>
#  select(A, B, starts_with("attn_")) |>
#  pivot_longer(
#   cols = c(starts_with("attn_")),
#   names_to = "nm",
#   values_to = "weights"
#  ) |>
#  mutate(
#   split_up = map(nm, ~ strsplit(.x, split = "_")[[1]]),
#   embedding_number = map_chr(split_up, ~ paste("Unattended", .x[3])),
#   attended_number = map_chr(split_up, ~ paste("Attended", .x[2]))
#  ) |>
#  ggplot(aes(A, B)) +
#  geom_tile(aes(fill = weights), show.legend = TRUE) +
#  # geom_contour(aes(z = weights), breaks = , col = "black") +
#  facet_grid(attended_number ~ embedding_number) +
#  scale_fill_gradient(low = "white", high = "#6EB245FF", limits = 0:1) +
#  coord_fixed() +
#  theme_bw()
# 
# print(p_att)
# 
# p_z <-
#  col_att_grid |>
#  select(A, B, starts_with("z_")) |>
#  pivot_longer(
#   cols = c(starts_with("z_")),
#   names_to = "nm",
#   values_to = "Attended"
#  ) |>
#  mutate(
#   split_up = map(nm, ~ strsplit(.x, split = "_")[[1]]),
#   embedding_number = map_chr(split_up, ~ paste("Embedding", .x[3])),
#   attended_number = map_chr(split_up, ~ paste("Attended", .x[2]))
#  ) |>
#  ggplot(aes(A, B)) +
#  geom_tile(aes(fill = Attended), show.legend = TRUE) +
#  geom_contour(aes(z = Attended), breaks = 0, col = "black") +
#  facet_grid(attended_number ~ embedding_number) +
#  scale_fill_gradient2(high = "#5D74A5FF") +
#  coord_fixed() +
#  theme_bw()
# print(p_z)

# ---- 8. Save artifacts ------------------------------------------------------

save(col_att_grid, file = "RData/col_att_demo.RData")

# state_dict() returns an OrderedDict-like list of parameter tensors. Saving
# the state dict (not the whole module) is the recommended idiom -- it's
# robust to small changes in the module definition.
# torch_save(model$state_dict(),
#            path = "/Users/max/tmp/att_demo/att_demo_model.pt")
#
# cli::cli_alert_success(
#   "Saved {.file att_demo_grid.rds} and {.file att_demo_model.pt} to {.path /Users/max/tmp/att_demo}"
# )
