library(tidymodels)
library(mirai)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
daemons(10)

# ------------------------------------------------------------------------------

load("~/content/website/RData/forested_data.RData")

split_example <-
  forested_train %>%
  dplyr::select(class, vapor_max)

if ("Yes" %in% levels(split_example$class)) {
  positive_class <- "Yes"
} else {
  positive_class <- levels(split_example$class)[1]
}

# Enumerate split points
unique_vals <- sort(unique(split_example$vapor_max))
grid_size <- length(unique_vals) - 2

# Midpoints between consecutive unique values
split_points <- (head(unique_vals, -1) + tail(unique_vals, -1)) / 2

# ------------------------------------------------------------------------------
# Gini and information

# Entropy function
entropy_binary <- function(p) {
  if (is.na(p)) {
    return(NA_real_)
  }
  if (p <= 0 || p >= 1) {
    return(0)
  }
  -(p * log2(p) + (1 - p) * log2(1 - p))
}

# Compute metrics for one split point s:
compute_split_metrics <- function(x, y, split_value, positive_class) {
  left_idx <- x <= split_value
  right_idx <- !left_idx

  n_left <- sum(left_idx)
  n_right <- sum(right_idx)
  n_total <- length(x)

  # Guard against degenerate splits
  if (n_left == 0 || n_right == 0) {
    return(tibble(
      split_value = split_value,
      left_count = n_left,
      right_count = n_right,
      left_prop = NA_real_,
      right_prop = NA_real_,
      gini_index = NA_real_,
      gini_gain = NA_real_,
      info_gain = NA_real_,
      gain_ratio = NA_real_
    ))
  }

  # Class proportions (positive class) in each node
  left_prop <- mean(y[left_idx] == positive_class)
  right_prop <- mean(y[right_idx] == positive_class)
  parent_prop <- mean(y == positive_class)

  # 1) Gini Index (as specified): pL(1-pL) + pR(1-pR)
  gini_idx <- left_prop * (1 - left_prop) + right_prop * (1 - right_prop)
  gini_before <- 2 * parent_prop * (1 - parent_prop)
  gini_gain <- gini_before - gini_idx

  # 2) Information Gain
  info_before <- entropy_binary(parent_prop)
  info_after <- (n_left / n_total) *
    entropy_binary(left_prop) +
    (n_right / n_total) * entropy_binary(right_prop)
  info_gain <- info_before - info_after

  # 3) Gain Ratio
  # Intrinsic information of the split: -sum_i w_i log2(w_i)
  w_left <- n_left / n_total
  w_right <- n_right / n_total
  intrinsic_info <- 0
  if (w_left > 0) {
    intrinsic_info <- intrinsic_info - w_left * log2(w_left)
  }
  if (w_right > 0) {
    intrinsic_info <- intrinsic_info - w_right * log2(w_right)
  }

  gain_ratio <- if (intrinsic_info > 0) info_gain / intrinsic_info else NA_real_

  tibble(
    split_value = split_value,
    left_count = n_left,
    right_count = n_right,
    left_prop = left_prop,
    right_prop = right_prop,
    gini_index = gini_idx,
    gini_gain = gini_gain,
    info_gain = info_gain,
    gain_ratio = gain_ratio
  )
}

split_lvls <-
  c(
    "Gini Gain",
    "Information Gain",
    "Information Gain Ratio",
    "Chi-Square",
    "XGBoost",
    "LightGBM",
    "CatBoost"
  )

#' Approximate XGBoost histogram-based split finding for binary classification
#'
#' @param x Numeric predictor vector
#' @param y Factor with two levels (converted to 0/1 internally)
#' @param max_bin Maximum number of histogram bins (default 256)
#' @param lambda L2 regularization on leaf weights (default 1)
#' @param gamma Minimum loss reduction for split (default 0)
#' @param min_child_weight Minimum sum of hessians in child (
#' @param base_score Initial prediction (default 0.5)
#' @return Data frame with split points and gain values
xgb_splits <- function(
  x,
  y,
  max_bin = 256L,
  lambda = 1,
  gamma = 0,
  min_child_weight = 1,
  base_score = 0.5
) {
  # Convert factor to 0/1

  if (!is.factor(y)) {
    y <- as.factor(y)
  }

  label <- as.integer(y) - 1L

  # Remove missing values

  valid <- !is.na(x) & !is.na(label)
  x <- x[valid]
  label <- label[valid]

  # Initial prediction (sigmoid of base margin)
  pred <- rep(base_score, length(label))

  # Compute gradients and hessians for logistic loss
  # g_i = p_i - y_i
  # h_i = p_i * (1 - p_i)

  grad <- pred - label
  hess <- pmax(pred * (1 - pred), 1e-16)

  # Build histogram bin edges using quantiles
  n_bins <- min(max_bin, length(unique(x)))
  probs <- seq(0, 1, length.out = n_bins + 1)
  cuts <- unique(quantile(x, probs, type = 7))

  # Bin assignments (which bin each observation falls into)
  bin_idx <- findInterval(x, cuts, rightmost.closed = TRUE)
  bin_idx <- pmax(1L, pmin(bin_idx, length(cuts) - 1L))

  # Aggregate G and H per bin
  n_bins_actual <- length(cuts) - 1L
  bin_grad <- tapply(grad, bin_idx, sum)
  bin_hess <- tapply(hess, bin_idx, sum)

  # Fill in zeros for empty bins
  all_bins <- seq_len(n_bins_actual)
  G <- H <- numeric(n_bins_actual)
  G[as.integer(names(bin_grad))] <- bin_grad
  H[as.integer(names(bin_hess))] <- bin_hess

  # Total gradient and hessian for the node
  G_total <- sum(G)
  H_total <- sum(H)

  # Calculate gain for each potential split point
  # Gain = 0.5 * [G_L^2/(H_L+λ) + G_R^2/(H_R+λ) - G^2/(H+λ)] - γ
  calc_gain <- function(g_left, h_left, g_right, h_right) {
    if (h_left < min_child_weight || h_right < min_child_weight) {
      return(-Inf)
    }
    gain_left <- g_left^2 / (h_left + lambda)
    gain_right <- g_right^2 / (h_right + lambda)
    gain_parent <- G_total^2 / (H_total + lambda)
    0.5 * (gain_left + gain_right - gain_parent) - gamma
  }

  # Enumerate all split points (cumulative sums for efficiency)
  G_cumsum <- cumsum(G)
  H_cumsum <- cumsum(H)

  # Split points are the upper edges of bins (except the last)
  split_points <- cuts[-1] # Remove first edge (minimum)
  split_points <- split_points[-length(split_points)] # Remove last edge

  n_splits <- length(split_points)
  gains <- numeric(n_splits)

  for (i in seq_len(n_splits)) {
    G_left <- G_cumsum[i]
    H_left <- H_cumsum[i]
    G_right <- G_total - G_left
    H_right <- H_total - H_left
    gains[i] <- calc_gain(G_left, H_left, G_right, H_right)
  }

  # Build result data frame
  results <- data.frame(
    split_value = split_points,
    score = gains,
    left_grad_sum = G_cumsum[seq_len(n_splits)],
    left_hess_sum = H_cumsum[seq_len(n_splits)],
    right_grad_sum = G_total - G_cumsum[seq_len(n_splits)],
    right_hess_sum = H_total - H_cumsum[seq_len(n_splits)]
  )

  # Add leaf weights for reference
  results$left_weight <- -results$left_grad_sum /
    (results$left_hess_sum + lambda)
  results$right_weight <- -results$right_grad_sum /
    (results$right_hess_sum + lambda)

  # Sort by gain descending

  results <- results[order(results$score, decreasing = TRUE), ]
  rownames(results) <- NULL
  results <- tibble::as_tibble(results)
  results$max_bin <- max_bin
  results$lambda <- lambda
  results$gamma <- gamma

  results
}

# ------------------------------------------------------------------------------

lgb_splits <- function(
  x,
  y,
  max_bin = 255L,
  lambda_l1 = 0.0,
  lambda_l2 = 0.0,
  min_data_in_leaf = 20L,
  min_sum_hessian_in_leaf = 1e-3,
  sigmoid = 1.0
) {
  # Convert factor to {-1, +1} labels (first level = -1, second = +1
  if (!is.factor(y)) {
    y <- as.factor(y)
  }
  stopifnot(nlevels(y) == 2L)
  label <- ifelse(as.integer(y) == 1L, -1.0, 1.0)

  # Remove NA values
  complete <- !is.na(x) & !is.na(label)
  x <- x[complete]
  label <- label[complete]
  n <- length(x)

  # Compute initial gradients and hessians (score = 0 at first iteration)

  # g = -label * sigmoid / (1 + exp(label * sigmoid * score))
  # At score=0: g = -label * sigmoid / 2
  grad <- -label * sigmoid / 2.0
  # h = |g| * (sigmoid - |g|)
  hess <- abs(grad) * (sigmoid - abs(grad))

  # Greedy binning: use quantiles to approximate LightGBM's data-adaptive bins
  distinct_vals <- sort(unique(x))
  n_distinct <- length(distinct_vals)

  if (n_distinct <= max_bin) {
    # Use midpoints between distinct values as bin boundaries
    bin_edges <- (distinct_vals[-n_distinct] + distinct_vals[-1]) / 2
  } else {
    # Use quantile-based binning
    probs <- seq(1 / max_bin, 1 - 1 / max_bin, length.out = max_bin - 1L)
    bin_edges <- unname(quantile(x, probs, type = 1))
    bin_edges <- unique(bin_edges)
  }

  # Sort data by predictor value
  ord <- order(x)
  x_sorted <- x[ord]
  grad_sorted <- grad[ord]
  hess_sorted <- hess[ord]

  # L1 soft thresholding function
  threshold_l1 <- function(s, l1) {
    sign(s) * pmax(0, abs(s) - l1)
  }

  # Compute gain for a leaf: ThresholdL1(sum_grad, l1)^2 / (sum_hess + l2)
  leaf_gain <- function(sum_grad, sum_hess) {
    if (lambda_l1 > 0) {
      threshold_l1(sum_grad, lambda_l1)^2 / (sum_hess + lambda_l2)
    } else {
      sum_grad^2 / (sum_hess + lambda_l2)
    }
  }

  # Parent node statistics
  total_grad <- sum(grad_sorted)
  total_hess <- sum(hess_sorted)
  parent_gain <- leaf_gain(total_grad, total_hess)

  # Evaluate each candidate split point
  results <- data.frame(
    split_value = numeric(0),
    score = numeric(0),
    left_count = integer(0),
    right_count = integer(0),
    left_grad_sum = numeric(0),
    right_grad_sum = numeric(0)
  )

  # Accumulate from left to right
  left_grad <- 0.0
  left_hess <- 0.0
  left_count <- 0L
  i <- 1L # index into sorted data

  for (threshold in bin_edges) {
    # Accumulate all points <= threshold into left child
    while (i <= n && x_sorted[i] <= threshold) {
      left_grad <- left_grad + grad_sorted[i]
      left_hess <- left_hess + hess_sorted[i]
      left_count <- left_count + 1L
      i <- i + 1L
    }

    right_count <- n - left_count
    right_grad <- total_grad - left_grad
    right_hess <- total_hess - left_hess

    # Check min_data_in_leaf constraint
    if (left_count < min_data_in_leaf || right_count < min_data_in_leaf) {
      next
    }

    # Check min_sum_hessian_in_leaf constraint
    if (
      left_hess < min_sum_hessian_in_leaf ||
        right_hess < min_sum_hessian_in_leaf
    ) {
      next
    }

    # Compute split gain: left_gain + right_gain - parent_gain
    split_gain <- leaf_gain(left_grad, left_hess) +
      leaf_gain(right_grad, right_hess) -
      parent_gain

    results <- rbind(
      results,
      data.frame(
        split_value = threshold,
        score = split_gain,
        left_count = left_count,
        right_count = right_count,
        left_grad_sum = left_grad,
        right_grad_sum = right_grad
      )
    )
  }

  # Sort by gain descending
  results <- results[order(-results$score), ]
  rownames(results) <- NULL

  results <- tibble::as_tibble(results)
  results$max_bin <- max_bin
  results$lambda_l1 <- lambda_l1
  results$lambda_l2 <- lambda_l2
  results$min_data_in_leaf <- min_data_in_leaf
  results$min_sum_hessian_in_leaf <- min_sum_hessian_in_leaf
  results$sigmoid <- sigmoid
  results
}

# ------------------------------------------------------------------------------

#' Approximate CatBoost Split Evaluation for Binary Classification
#'
#' Evaluates potential split points for a numeric predictor using CatBoost's
#' default L2 scoring method with log-loss gradients for binary classification.
#'
#' @param x Numeric vector of predictor values. NaN values are handled according
#'   to \code{nan_mode}.
#' @param y Factor vector with exactly two levels representing the binary outcome.
#'   The second level is treated as the positive class (coded as 1).
#' @param max_bin Integer. Maximum number of splits (split points) to
#'   evaluate. Default is 254, matching CatBoost's CPU default.
#' @param binning_method Character. Method for selecting candidate splits. One of
#'   \code{"GreedyLogSum"} (default), \code{"Median"}, \code{"Uniform"},
#'   \code{"UniformAndQuantiles"}, \code{"MinEntropy"}, or \code{"MaxLogSum"}.
#' @param l2_reg Numeric. L2 regularization parameter for leaf value calculation.
#'   Default is 3, matching CatBoost's default.
#' @param nan_mode Character. How to handle NaN values. One of \code{"Min"}
#'   (default, NaN goes to smallest bin), \code{"Max"} (NaN goes to largest bin),
#'   or \code{"Forbidden"} (error if NaN present).
#' @param initial_prediction Numeric. Initial prediction value (in log-odds scale
#'   for binary classification). Default is 0, corresponding to probability 0.5.
#'
#' @return A data frame with columns:
#'   \describe{
#'     \item{split_value}{The split threshold value}
#'     \item{score}{The L2 score for this split (higher is better)}
#'     \item{left_count}{Number of samples in the left child (value <= split)}
#'     \item{right_count}{Number of samples in the right child (value > split)}
#'     \item{left_grad_sum}{Sum of gradients in the left child}
#'     \item{right_grad_sum}{Sum of gradients in the right child}
#'     \item{left_weight}{Optimal leaf value for left child}
#'     \item{right_weight}{Optimal leaf value for right child}
#'   }
#'   Rows are sorted by descending score.
#'
#' @details
#' This function approximates CatBoost's split evaluation for the first split
#' of a gradient boosting tree with binary log-loss. The process has two phases
#' that use two different objective functions:
#'
#' **Phase 1 - Split Selection (Quantization):**
#' Candidate split points are selected using the specified \code{binning_method}

#' algorithm. The default \code{"GreedyLogSum"} greedily partitions the feature
#' space to maximize \eqn{\sum \log(n_i)} where \eqn{n_i} is the count in each bin.
#' This phase only considers the predictor distribution, not the outcome.
#'
#' **Phase 2 - Split Scoring:**
#' Each candidate split is scored using gradient statistics. For binary
#' log-loss with current probability \eqn{p_i}:
#' \itemize{
#'   \item Gradient: \eqn{g_i = y_i - p_i}
#'   \item Leaf value: \eqn{v = \sum g_i / (n + \lambda)}
#'   \item Split score: \eqn{S = v_L \sum g_L + v_R \sum g_R}
#' }
#' where \eqn{\lambda} is \code{l2_reg} and subscripts L/R denote left/right children.
#'
#' @examples
#' set.seed(42)
#' x <- c(rnorm(50, mean = 2), rnorm(50, mean = 5))
#' y <- factor(c(rep("no", 50), rep("yes", 50)))
#'
#' # Evaluate splits
#' result <- cat_splits(x, y)
#' head(result)
#'
#' # Best split
#' result[1, ]
#'
#' # With different split selection
#' result_median <- cat_splits(x, y, binning_method = "Median")
#'
#' @export
cat_splits <- function(
  x,
  y,
  max_bin = 254L,
  binning_method = c(
    "Uniform",
    "GreedyLogSum",
    "Median",
    "UniformAndQuantiles",
    "MinEntropy",
    "MaxLogSum"
  ),
  l2_reg = 3,
  nan_mode = c("Min", "Max", "Forbidden"),
  initial_prediction = 0
) {
  # Validate inputs

  binning_method <- match.arg(binning_method)
  nan_mode <- match.arg(nan_mode)

  if (!is.numeric(x)) {
    stop("`x` must be a numeric vector")
  }
  if (!is.factor(y)) {
    stop("`y` must be a factor")
  }
  if (length(x) != length(y)) {
    stop("`x` and `y` must have the same length")
  }
  if (nlevels(y) != 2L) {
    stop("`y` must have exactly 2 levels")
  }
  if (max_bin < 1L) {
    stop("`max_bin` must be at least 1")
  }
  if (l2_reg < 0) {
    stop("`l2_reg` must be non-negative")
  }

  # Handle NaN values

  nan_mask <- is.nan(x)
  has_nans <- any(nan_mask)

  if (has_nans && nan_mode == "Forbidden") {
    stop("NaN values found in `x` but nan_mode = 'Forbidden'")
  }

  # Separate NaN and non-NaN data
  x_clean <- x[!nan_mask]
  y_clean <- y[!nan_mask]
  y_nan <- y[nan_mask]

  # Convert outcome to 0/1

  y_numeric <- as.integer(y_clean) - 1L
  y_nan_numeric <- as.integer(y_nan) - 1L

  # Calculate gradients (for log-loss: gradient = y - p)

  p_initial <- 1 / (1 + exp(-initial_prediction))
  gradients <- y_numeric - p_initial
  gradients_nan <- y_nan_numeric - p_initial

  # Phase 1: Select candidate splits (excluding NaN)

  splits <- select_binning_method(
    x = x_clean,
    max_bin = if (has_nans) max_bin - 1L else max_bin,
    method = binning_method
  )

  if (length(splits) == 0L) {
    warning("No valid splits found (feature may be constant)")
    return(data.frame(
      split_value = numeric(0),
      score = numeric(0),
      left_count = integer(0),
      right_count = integer(0),
      left_grad_sum = numeric(0),
      right_grad_sum = numeric(0),
      left_weight = numeric(0),
      right_weight = numeric(0)
    ))
  }

  # Phase 2: Score each split

  n_splits <- length(splits)
  results <- vector("list", n_splits)

  # Sort data for efficient cumulative sums
  ord <- order(x_clean)
  x_sorted <- x_clean[ord]
  g_sorted <- gradients[ord]

  # Cumulative sums for left child statistics
  cumsum_g <- cumsum(g_sorted)
  cumsum_n <- seq_along(g_sorted)

  total_g <- sum(gradients)
  total_n <- length(gradients)

  # Add NaN gradients based on nan_mode
  if (has_nans) {
    nan_g <- sum(gradients_nan)
    nan_n <- length(gradients_nan)
  } else {
    nan_g <- 0
    nan_n <- 0L
  }

  for (i in seq_along(splits)) {
    split <- splits[i]

    # Find split point: left = values <= split
    split_idx <- sum(x_sorted <= split)

    if (split_idx == 0L) {
      # All values go right
      left_g <- 0
      left_n <- 0L
      right_g <- total_g
      right_n <- total_n
    } else if (split_idx == total_n) {
      # All values go left
      left_g <- total_g
      left_n <- total_n
      right_g <- 0
      right_n <- 0L
    } else {
      left_g <- cumsum_g[split_idx]
      left_n <- cumsum_n[split_idx]
      right_g <- total_g - left_g
      right_n <- total_n - left_n
    }

    # Add NaN samples based on nan_mode
    if (has_nans) {
      if (nan_mode == "Min") {
        # NaN goes left (smallest bin)
        left_g <- left_g + nan_g
        left_n <- left_n + nan_n
      } else {
        # nan_mode == "Max": NaN goes right (largest bin)
        right_g <- right_g + nan_g
        right_n <- right_n + nan_n
      }
    }

    # Calculate leaf values with L2 regularization
    # Formula: leaf_value = sum_gradient / (count + l2_reg)
    left_leaf <- if (left_n > 0) left_g / (left_n + l2_reg) else 0
    right_leaf <- if (right_n > 0) right_g / (right_n + l2_reg) else 0

    # Calculate L2 score
    # Formula: score = left_leaf * left_sum_gradient + right_leaf * right_sum_gradient
    score <- left_leaf * left_g + right_leaf * right_g

    results[[i]] <- data.frame(
      split_value = split,
      score = score,
      left_count = left_n,
      right_count = right_n,
      left_grad_sum = left_g,
      right_grad_sum = right_g,
      left_weight = left_leaf,
      right_weight = right_leaf
    )
  }

  results <- do.call(rbind, results)

  # Sort by score descending (best splits first)
  results <- results[order(-results$score), ]
  rownames(results) <- NULL

  results <- tibble::as_tibble(results)
  results$max_bin <- max_bin
  results$binning_method <- binning_method
  results$l2_reg <- l2_reg
  results$nan_mode <- nan_mode
  results$initial_prediction <- initial_prediction
  results
}


#' Select split Candidates for Quantization
#'
#' Internal function that selects candidate split points using various
#' split selection algorithms.
#'
#' @param x Numeric vector (NaN values should already be removed).
#' @param max_bin Maximum number of splits to return.
#' @param method split selection method.
#'
#' @return Numeric vector of split values.
#'
#' @keywords internal
select_binning_method <- function(x, max_bin, method) {
  if (length(x) < 2L) {
    return(numeric(0))
  }

  x_sorted <- sort(unique(x))
  n_unique <- length(x_sorted)

  if (n_unique < 2L) {
    return(numeric(0))
  }

  # Maximum possible splits is n_unique - 1
  max_bin <- min(max_bin, n_unique - 1L)

  splits <- switch(
    method,
    "Uniform" = binning_uniform(x_sorted, max_bin),
    "Median" = binning_median(x, max_bin),
    "UniformAndQuantiles" = binning_uniform_and_quantiles(
      x,
      max_bin
    ),
    "GreedyLogSum" = binning_greedy_logsum(x, max_bin),
    "GreedyMinEntropy" = binning_greedy_entropy(
      x,
      max_bin,
      maximize = FALSE
    ),
    "MaxLogSum" = binning_exact_logsum(x, max_bin),
    "MinEntropy" = binning_exact_entropy(x, max_bin)
  )

  sort(unique(splits))
}


#' Uniform Split Selection
#' @keywords internal
binning_uniform <- function(x_sorted, max_bin) {
  min_val <- x_sorted[1]
  max_val <- x_sorted[length(x_sorted)]

  if (min_val == max_val) {
    return(numeric(0))
  }

  # splits at equal intervals
  seq(
    from = min_val + (max_val - min_val) / (max_bin + 1),
    to = max_val - (max_val - min_val) / (max_bin + 1),
    length.out = max_bin
  )
}


#' Median (Quantile) Split Selection
#' @keywords internal
binning_median <- function(x, max_bin) {
  # splits at quantile positions
  probs <- seq(0, 1, length.out = max_bin + 2)
  probs <- probs[-c(1, length(probs))]
  quantiles <- quantile(x, probs = probs, type = 1, names = FALSE)

  # Place splits between adjacent unique values
  x_sorted <- sort(x)
  splits <- numeric(length(quantiles))

  for (i in seq_along(quantiles)) {
    q <- quantiles[i]
    idx <- sum(x_sorted <= q)
    if (idx > 0 && idx < length(x_sorted)) {
      # Midpoint between adjacent values
      splits[i] <- (x_sorted[idx] + x_sorted[idx + 1]) / 2
    } else if (idx == 0) {
      splits[i] <- x_sorted[1] - 1
    } else {
      splits[i] <- x_sorted[length(x_sorted)]
    }
  }

  unique(splits)
}


#' Uniform and Quantiles Split Selection (CatBoost default for training data)
#' @keywords internal
#' @keywords internal
binning_uniform_and_quantiles <- function(x, max_bin) {
  # Half from median, half from uniform
  n_median <- max_bin - max_bin %/% 2
  n_uniform <- max_bin %/% 2

  x_sorted <- sort(unique(x))

  splits_median <- if (n_median > 0) {
    binning_median(x, n_median)
  } else {
    numeric(0)
  }

  splits_uniform <- if (n_uniform > 0) {
    binning_uniform(x_sorted, n_uniform)
  } else {
    numeric(0)
  }

  sort(unique(c(splits_median, splits_uniform)))
}


#' Greedy LogSum Split Selection (CatBoost default)
#'
#' Greedily selects splits to maximize sum of log(bin_count).
#' At each step, splits the bin that yields the maximum score improvement.
#'
#' @keywords internal
binning_greedy_logsum <- function(x, max_bin) {
  x_sorted <- sort(x)
  n <- length(x_sorted)

  if (n < 2 || max_bin < 1) {
    return(numeric(0))
  }

  # Score function: sum of log(count) for each bin

  # Splitting bin with count w into w_L and w_R:

  # score_improvement = log(w_L) + log(w_R) - log(w)
  calc_split_score <- function(w_left, w_right, w_total) {
    if (w_left <= 0 || w_right <= 0) {
      return(-Inf)
    }
    log(w_left) + log(w_right) - log(w_total)
  }

  # Initialize: one bin with all data

  # bins: list of (start_idx, end_idx) in x_sorted

  bins <- list(c(1L, n))

  # Find best split for a bin
  find_best_split <- function(bin_start, bin_end) {
    bin_size <- bin_end - bin_start + 1L
    if (bin_size < 2L) {
      return(list(score = -Inf, split_idx = NA, split = NA))
    }

    # Try splitting at midpoint (greedy heuristic)
    mid_idx <- bin_start + bin_size %/% 2L - 1L

    # Find actual split point between unique values
    best_score <- -Inf
    best_idx <- NA
    best_split <- NA

    # Check a few candidate positions around the midpoint
    candidates <- unique(c(
      max(bin_start, mid_idx - 2L):min(bin_end - 1L, mid_idx + 2L)
    ))

    for (idx in candidates) {
      # split between x_sorted[idx] and x_sorted[idx + 1]
      if (x_sorted[idx] < x_sorted[idx + 1L]) {
        w_left <- idx - bin_start + 1L
        w_right <- bin_end - idx
        score <- calc_split_score(w_left, w_right, bin_size)

        if (score > best_score) {
          best_score <- score
          best_idx <- idx
          best_split <- (x_sorted[idx] + x_sorted[idx + 1L]) / 2
        }
      }
    }

    list(score = best_score, split_idx = best_idx, split = best_split)
  }

  splits <- numeric(0)

  for (iter in seq_len(max_bin)) {
    # Find the best split across all current bins
    best_overall <- list(
      score = -Inf,
      bin_idx = NA,
      split_idx = NA,
      split = NA
    )

    for (b in seq_along(bins)) {
      bin <- bins[[b]]
      split_info <- find_best_split(bin[1], bin[2])

      if (split_info$score > best_overall$score) {
        best_overall <- list(
          score = split_info$score,
          bin_idx = b,
          split_idx = split_info$split_idx,
          split = split_info$split
        )
      }
    }

    # If no valid split found, stop
    if (is.infinite(best_overall$score) || is.na(best_overall$split)) {
      break
    }

    # Record the split
    splits <- c(splits, best_overall$split)

    # Split the bin
    old_bin <- bins[[best_overall$bin_idx]]
    new_bin_left <- c(old_bin[1], best_overall$split_idx)
    new_bin_right <- c(best_overall$split_idx + 1L, old_bin[2])

    bins[[best_overall$bin_idx]] <- new_bin_left
    bins <- append(bins, list(new_bin_right), after = best_overall$bin_idx)
  }

  sort(splits)
}


#' Greedy Min-Entropy Split Selection
#'
#' Greedily selects splits to minimize entropy (or maximize negative entropy).
#'
#' @keywords internal
binning_greedy_entropy <- function(x, max_bin, maximize = FALSE) {
  x_sorted <- sort(x)
  n <- length(x_sorted)

  if (n < 2 || max_bin < 1) {
    return(numeric(0))
  }

  # Entropy penalty: w * log(w)
  # Splitting score: -w_L*log(w_L) - w_R*log(w_R) + w*log(w)
  calc_split_score <- function(w_left, w_right, w_total) {
    if (w_left <= 0 || w_right <= 0) {
      return(-Inf)
    }
    penalty_left <- w_left * log(w_left)
    penalty_right <- w_right * log(w_right)
    penalty_total <- w_total * log(w_total)
    -penalty_left - penalty_right + penalty_total
  }

  # Same structure as greedy_logsum but with different score function
  bins <- list(c(1L, n))

  find_best_split <- function(bin_start, bin_end) {
    bin_size <- bin_end - bin_start + 1L
    if (bin_size < 2L) {
      return(list(score = -Inf, split_idx = NA, split = NA))
    }

    mid_idx <- bin_start + bin_size %/% 2L - 1L
    best_score <- -Inf
    best_idx <- NA
    best_split <- NA

    candidates <- unique(c(
      max(bin_start, mid_idx - 2L):min(bin_end - 1L, mid_idx + 2L)
    ))

    for (idx in candidates) {
      if (x_sorted[idx] < x_sorted[idx + 1L]) {
        w_left <- idx - bin_start + 1L
        w_right <- bin_end - idx
        score <- calc_split_score(w_left, w_right, bin_size)

        if (score > best_score) {
          best_score <- score
          best_idx <- idx
          best_split <- (x_sorted[idx] + x_sorted[idx + 1L]) / 2
        }
      }
    }

    list(score = best_score, split_idx = best_idx, split = best_split)
  }

  splits <- numeric(0)

  for (iter in seq_len(max_bin)) {
    best_overall <- list(
      score = -Inf,
      bin_idx = NA,
      split_idx = NA,
      split = NA
    )

    for (b in seq_along(bins)) {
      bin <- bins[[b]]
      split_info <- find_best_split(bin[1], bin[2])

      if (split_info$score > best_overall$score) {
        best_overall <- list(
          score = split_info$score,
          bin_idx = b,
          split_idx = split_info$split_idx,
          split = split_info$split
        )
      }
    }

    if (is.infinite(best_overall$score) || is.na(best_overall$split)) {
      break
    }

    splits <- c(splits, best_overall$split)

    old_bin <- bins[[best_overall$bin_idx]]
    new_bin_left <- c(old_bin[1], best_overall$split_idx)
    new_bin_right <- c(best_overall$split_idx + 1L, old_bin[2])

    bins[[best_overall$bin_idx]] <- new_bin_left
    bins <- append(bins, list(new_bin_right), after = best_overall$bin_idx)
  }

  sort(splits)
}


#' Exact LogSum Split Selection (Dynamic Programming)
#'
#' Finds globally optimal splits using O(n^2 * k) dynamic programming.
#'
#' @keywords internal
binning_exact_logsum <- function(x, max_bin) {
  # For simplicity, fall back to greedy for large datasets
  if (length(x) > 1000) {
    message("Using greedy approximation for large dataset")
    return(binning_greedy_logsum(x, max_bin))
  }

  x_sorted <- sort(x)
  n <- length(x_sorted)

  if (n < 2 || max_bin < 1) {
    return(numeric(0))
  }

  # Group identical values
  rle_x <- rle(x_sorted)
  values <- rle_x$values
  counts <- rle_x$lengths
  m <- length(values)

  if (m < 2) {
    return(numeric(0))
  }

  k <- min(max_bin, m - 1L)
  cum_counts <- cumsum(counts)

  # penalty(i, j) = -log(sum of counts from i to j)
  penalty <- function(i, j) {
    w <- if (i == 1) cum_counts[j] else cum_counts[j] - cum_counts[i - 1]
    -log(w + 1e-10)
  }

  # DP: dp[j, b] = min total penalty for first j groups with b splits

  # We want to maximize sum of log(counts), i.e., minimize sum of -log(counts)
  dp <- matrix(Inf, nrow = m, ncol = k + 1)
  parent <- matrix(NA_integer_, nrow = m, ncol = k + 1)

  # Base case: 0 splits (one bin)
  for (j in seq_len(m)) {
    dp[j, 1] <- penalty(1, j)
  }

  # Fill DP table

  for (b in 2:(k + 1)) {
    for (j in b:m) {
      for (i in (b - 1):(j - 1)) {
        cost <- dp[i, b - 1] + penalty(i + 1, j)
        if (cost < dp[j, b]) {
          dp[j, b] <- cost
          parent[j, b] <- i
        }
      }
    }
  }

  # Backtrack to find splits
  splits <- numeric(0)
  j <- m
  b <- k + 1

  while (b > 1 && !is.na(parent[j, b])) {
    i <- parent[j, b]
    # split between group i and i+1
    split <- (values[i] + values[i + 1]) / 2
    splits <- c(split, splits)
    j <- i
    b <- b - 1
  }

  splits
}


#' Exact Min-Entropy Split Selection (Dynamic Programming)
#' @keywords internal
binning_exact_entropy <- function(x, max_bin) {
  # For simplicity, fall back to greedy for large datasets
  if (length(x) > 1000) {
    message("Using greedy approximation for large dataset")
    return(binning_greedy_entropy(x, max_bin))
  }

  # Similar to exact_logsum but with entropy penalty
  # For brevity, use greedy version

  binning_greedy_entropy(x, max_bin, maximize = FALSE)
}

# Entropy function
entropy_binary <- function(p) {
  if (is.na(p)) {
    return(NA_real_)
  }
  if (p <= 0 || p >= 1) {
    return(0)
  }
  -(p * log2(p) + (1 - p) * log2(1 - p))
}

# ------------------------------------------------------------------------------

ctree_score <- function(split_value, x, y, ...) {
  require(coin)
  dat <-
    tibble::tibble(predictor = x, class = y) |>
    dplyr::mutate(
      group = ifelse(predictor <= split_value, "left", "right"),
      group = factor(group, levels = c("left", "right"))
    )
  if (all(table(dat$group) == 0L)) {
    browser()
    res <-
      tibble::tibble(
        split_value = split_value,
        p_value = NA_real_,
        score = NA_real_
      )
  } else {}
  res <- coin::chisq_test(class ~ group, data = dat, ...)
  res <- tibble::tibble(
    split_value = split_value,
    p_value = -log10(as.numeric(coin::pvalue(res))),
    score = statistic(res)
  )
  res
}

ctree_split <- function(x, y, ...) {
  splits <- sort(unique(x))
  splits <- splits[-c(1, length(splits))]
  # purrr::map_dfr(splits, ctree_score, x, y)
  args <- list(x = x, y = y)
  dots <- list(...)
  args <- c(args, dots)
  res <- mirai::mirai_map(splits, ctree_score, .args = args)
  res <- purrr::list_rbind(res[])
  res
}

# ------------------------------------------------------------------------------

plot_splits <- function(x) {
  res <- all_res[all_res$metric == x, ]
  other_res <- all_res[all_res$metric != x, ]

  bst <- dplyr::slice_max(res, value, n = 1)

  ggplot(other_res, aes(x = split_value, y = unit_value)) +
    geom_line(aes(group = metric), show.legend = FALSE, alpha = 1 / 5) +
    geom_line(data = res, col = "blue", linewidth = 1) +
    geom_vline(
      aes(xintercept = bst$split_value),
      color = "lightblue",
      linetype = "dashed",
      linewidth = 1
    ) +
    labs(
      x = "Maximum Vapor Split Point",
      y = x
    ) +
    theme_bw(base_size = 12) +
    theme(strip.text = element_text(face = "bold"))
}

# ------------------------------------------------------------------------------
# compute splits

gini_info_res <- purrr::map_dfr(
  split_points,
  ~ compute_split_metrics(
    x = split_example$vapor_max,
    y = split_example$class,
    split_value = .x,
    positive_class = positive_class
  )
) %>%
  dplyr::select(split_value, gini_gain, info_gain, gain_ratio) %>%
  pivot_longer(
    cols = c(gini_gain, info_gain, gain_ratio),
    names_to = "metric",
    values_to = "value"
  ) %>%
  mutate(
    metric = factor(
      metric,
      levels = c("gini_gain", "info_gain", "gain_ratio"),
      labels = c("Gini Gain", "Information Gain", "Information Gain Ratio")
    )
  )

ctree_res <- ctree_split(
  split_example$vapor_max,
  split_example$class,
  teststat = "quadratic"
) |>
  mutate(metric = "Chi-Square") |>
  dplyr::select(split_value, value = score, metric)

# ------------------------------------------------------------------------------

xgb_defaults <-
  xgb_splits(
    split_example$vapor_max,
    split_example$class,
    max_bin = grid_size
  ) |>
  dplyr::select(split_value, value = score) |>
  mutate(metric = "XGBoost")

lgb_defaults <-
  lgb_splits(
    split_example$vapor_max,
    split_example$class,
    max_bin = grid_size
  ) |>
  dplyr::select(split_value, value = score) |>
  mutate(metric = "LightGBM")

cat_defaults <-
  cat_splits(
    split_example$vapor_max,
    split_example$class,
    binning_method = "Uniform",
    max_bin = grid_size
  ) |>
  dplyr::select(split_value, value = score) |>
  mutate(metric = "CatBoost")

# ------------------------------------------------------------------------------

forested_split_examples <-
  gini_info_res |>
  dplyr::select(split_value, value, metric) |>
  bind_rows(ctree_res, xgb_defaults, lgb_defaults, cat_defaults) |>
  mutate(metric = factor(metric, levels = split_lvls))

metric_rngs <-
  forested_split_examples |>
  summarize(
    min_val = min(value),
    max_val = max(value),
    .by = c(metric)
  )

forested_split_examples <-
  forested_split_examples |>
  full_join(metric_rngs, by = "metric") |>
  mutate(
    unit_value = (value - min_val) / (max_val - min_val)
  )

# ------------------------------------------------------------------------------

save(forested_split_examples, file = "RData/forested_split_examples.RData")
