library(tabpfn)
reticulate::import('torch')
library(dplyr)
library(purrr)
# ------------------------------------------------------------------------------

load("~/content/website/RData/forested_data.RData")

# ------------------------------------------------------------------------------


i <- 1
set.seed(i)
icl_fit <- tab_pfn(
  class ~.,
  data = forested_train,
  num_estimators = 1
)


counties <- levels(forested_train$county)

sampled <- NULL
all_pfn_pred <- NULL

for (rep in 1:12) {
  for (shuf in c("yes", "no")) {
    
    tmp_train <- forested_train
    tmp_test <- forested_test
    
    if (shuf == "yes") {
      new_county <- sample(counties)
      new_cls <- sample(levels(forested_train$class))
      new_order <- sample(seq_len(ncol(forested_train)))
      tmp_train$county <- factor(as.character(tmp_train$county), level = new_county)
      tmp_test$county <- factor(as.character(tmp_test$county), level = new_county)
      tmp_train$class <- factor(as.character(tmp_train$class), level = new_cls)
      tmp_test$class <- factor(as.character(tmp_test$class), level = new_cls)
      tmp_train <- tmp_train[, new_order]
      tmp_test <- tmp_test[, new_order]
    } else
      
      icl_fit <- tab_pfn(
        class ~.,
        data = tmp_train,
        num_estimators = 1
      )
    
    icl_pred <- 
      predict(icl_fit, tmp_test, type = "prob") |> 
      select(.pred_Yes, .pred_No) |> 
      bind_cols(tmp_test |> select(class)) |> 
      parsnip::add_rowindex() |> 
      mutate(
        replicate = rep,
        shuffled = shuf
      )
    all_pfn_pred <- bind_rows(all_pfn_pred, icl_pred)
  }
}
  
for (shuf in c("yes", "no")) {
  for (i in (1:6) * 2) {
    for (j in 1:10) {
      tmp <- 
        all_pfn_pred |> 
        filter(shuffled == shuf) |> 
        slice_sample(n = 2, by = .row) |> 
        summarize(
          mean = mean(.pred_Yes),
          sd = sd(.pred_Yes), .by = c(.row)
        ) |> 
        mutate(num_estimators = i, shuffled = shuf)
      sampled <- bind_rows(sampled, tmp)
      
    }
  }
}

summarized <- 
  sampled |> 
  summarize(
    mean = mean(mean),
    sd = sd(sd),
    .by = c(.row, num_estimators, shuffled)
  )

summarized |> 
  ggplot(aes(mean, sd)) + 
  geom_point() + 
  facet_wrap(~ num_estimators)

summarized |> 
  mutate(num_estimators = format(num_estimators)) |> 
  ggplot(aes(mean, sd, col = num_estimators, group = num_estimators)) + 
  geom_line(stat="smooth", se = FALSE, method = "loess", formula = y ~ x, linewidth = 1.2, alpha =1 / 2) + 
  facet_wrap(~shuffled) +
  scale_color_viridis_d() + 
  labs(x = "Mean Estimate", y = "Estimate Std. Dev", color = "# Estimators")


save(summarized, file = "~/content/website/RData/tab_pfn_replicates.RData")

