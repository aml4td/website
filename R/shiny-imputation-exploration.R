ui <- fluidPage(
  theme = grid_theme,
  fluidRow(
    column(
      width = 2,
      radioButtons(
        "selection", "Select data:",
        choices = c(`Nonlinear` = "NONLINEAR", `Linear` = "LINEAR")
      )
    ), # data type
    column(
      width = 5,
      sliderInput("pctMissing", "Percent Missing:", min = 1, max = 30, value = 10, step = 1)
    ), # amount missing
    
    column(
      width = 5,
      selectInput(
        "imputeType", "Imputation Technique:",
        c(`Mean` = "MEANIMPUTE",
          `Median` = "MEDIANIMPUTE",
          `Bagged Tree` = "BAGIMPUTE",
          `k-NN` = "KNNIMPUTE",
          `Linear Regression` = "LINEARIMPUTE"
        )
      )
    ),  # imputation method
    fluidRow(
      column(
        width = 2,
        actionButton("update", "Update")
      ),
      column(
        width = 8,
        align = "center",
        plotOutput('plot')
      )
    )
  ) # top fluid row
)

load(url("https://raw.githubusercontent.com/aml4td/website/main/RData/simulation_data.RData"))

server <-
  function(input, output, session) {
    update_app <- reactive({
      input$update
      isolate({
        withProgress({
          setProgress(message = "Updating...")
          getData(DATA = input$selection,
                  PCTMISSING = input$pctMissing,
                  IMPUTETYPE = input$imputeType)
        })
      })
    })
    
    output$plot <- renderPlot({
      v <- update_app()
      
      f1 <-
        ggplot(v$for_figure, aes(x1, x2, pch = Obs_Type, color = Obs_Type)) +
        facet_grid(cols = vars(Type)) +
        geom_point(size=3) +
        scale_color_manual(values = c("#56B4E9", "#D55E00", "#56B4E9", "#D55E00")) +
        scale_shape_manual(values = c(16, 17, 1, 2)) +
        lims(x = v$xlims, y = v$ylims) +
        labs(x = "Predictor 1", y = "Predictor 2") +
        theme_light_bl() +
        theme(
          axis.title.x = element_text(size = 24),
          axis.text.x = element_text(size = 12),
          axis.title.y = element_text(size = 24),
          axis.text.y = element_text(size = 12),
          strip.text = element_text(size = 16),
          legend.position = "none"
        )
      
      if(v$linear_partition){
        f1 + geom_abline(slope = 1, intercept = 4, color = "black", 
                         linewidth = 1, linetype = 2)
      } else {
        f1 + stat_function(
          fun = function(x) (x ^ 2) / 2 + 4,
          linewidth = 1,
          color = "black",
          linetype = 2)
      }
      
    }, height = 300, width = 2 * 300)
  }

getData <- function(DATA = inputData,
                    PCTMISSING = inputPctMissing,
                    IMPUTETYPE = inputImputeType) {
  
  linear_partition <- ifelse(DATA == "LINEAR", "TRUE", "FALSE")
  if(linear_partition){
    current_data <-
      simulation_data %>%
      dplyr::filter(relationship == "linear") %>%
      dplyr::select(-relationship)
  } else {
    current_data <-
      simulation_data %>%
      dplyr::filter(relationship == "nonlinear") %>%
      dplyr::select(-relationship)
  }
  xlims = extendrange(current_data$x1)
  ylims = extendrange(current_data$x2)
  
  #Randomly select rows of predictor values to remove
  set.seed(1009)
  rows_missing <- sample(1:nrow(current_data), size=PCTMISSING*nrow(current_data)/100, replace=FALSE)
  x1_missing <- rows_missing[1:(length(rows_missing)/2)]
  x2_missing <- rows_missing[((length(rows_missing)/2)+1):length(rows_missing)]
  
  current_data$x1_new <- current_data$x1
  current_data$x2_new <- current_data$x2
  current_data$x1_new[x1_missing] <- NA
  current_data$x2_new[x2_missing] <- NA
  
  current_recipe <- 
    recipe(Observed ~ x1_new + x2_new , data = current_data)
  
  if(IMPUTETYPE == "BAGIMPUTE"){
    current_recipe <- current_recipe %>% step_impute_bag(all_predictors())
  } else if(IMPUTETYPE == "KNNIMPUTE"){
    current_recipe <- current_recipe %>% step_impute_knn(all_predictors())
  } else if(IMPUTETYPE == "MEANIMPUTE"){
    current_recipe <- current_recipe %>% step_impute_mean(all_predictors())
  } else if(IMPUTETYPE == "MEDIANIMPUTE"){
    current_recipe <- current_recipe %>% step_impute_median(all_predictors())
  } else if(IMPUTETYPE == "LINEARIMPUTE"){
    
    if (DATA == "LINEAR") {
      current_recipe <- current_recipe %>% step_impute_linear(all_predictors())
    } else {
      current_recipe <- 
        current_recipe %>% 
        step_impute_linear(x1_new, impute_with = imp_vars(x2_new)) %>% 
        step_mutate(x1_new_sq =  x1_new * x1_new) %>% 
        step_impute_linear(x1_new, impute_with = imp_vars(x2_new)) %>% 
        step_impute_linear(x2_new, impute_with = imp_vars(x2_new, x1_new_sq)) %>% 
        step_rm(x1_new_sq)
    }
    
  }
  
  current_recipe <- prep(current_recipe, training = current_data, retain = TRUE)
  impute_data <- bake(current_recipe, current_data)
  
  impute_data <- 
    impute_data %>%
    rename(x1 = x1_new, x2 = x2_new) %>%
    mutate(Type = "Imputed") %>% 
    dplyr::slice(rows_missing)
  
  orig_data <- 
    current_data %>%
    mutate(Type = "Original") %>%
    dplyr::select(x1, x2, Observed, Type) %>% 
    dplyr::slice(rows_missing)
  
  groups <- c("Group1: Original", "Group2: Original", "Group1: Imputed", "Group2: Imputed")
  for_figure <- 
    bind_rows(orig_data, impute_data)  %>%
    mutate(Obs_Type = factor(paste0(Observed, ": ", Type), levels = groups),
           Type = factor(Type, levels = c("Original", "Imputed")))
  
  list(for_figure = for_figure,
       xlims = xlims,
       ylims = ylims,
       linear_partition = linear_partition)
}
app <- shinyApp(ui = ui, server = server)
