library(shiny)
library(bslib)
library(tidymodels)
library(splines2)
library(scales)


light_bg <- "#fcfefe" # from aml4td.scss
grid_theme <- bs_theme(
  bg = light_bg, fg = "#595959"
)

theme_light_bl<- function(...) {
  
  ret <- ggplot2::theme_bw(...)
  
  col_rect <- ggplot2::element_rect(fill = light_bg, colour = light_bg)
  ret$panel.background  <- col_rect
  ret$plot.background   <- col_rect
  ret$legend.background <- col_rect
  ret$legend.key        <- col_rect
  
  ret$legend.position <- "top"
  
  ret
}

# ------------------------------------------------------------------------------


ui <- page_fillable(
  theme = bs_theme(bg = "#fcfefe", fg = "#595959"),
  padding = "1rem",
  layout_columns(
    fill = FALSE,
    col_widths = breakpoints(sm = c(-1, 5, 5, -1)),
    column(
      width = 4,
      checkboxGroupInput(
        inputId = "include",
        label = "Include",
        choices = list("Data" = "Data", "Linear" = "fit_linear", 
                       "Splines" = "fit_spline", GAM = "fit_gam"),
        selected = c("Data", "fit_linear"),
        inline = TRUE
      )
    ),
    column(
      width = 4,
      radioButtons(
        inputId = "yaxis",
        label = "y-axis",
        choices = c("Event Rate" = "rate", "Logit" = "logit"),
        inline = TRUE
      )
    )
  ),
  as_fill_carrier(plotOutput("plot"))
)


server <- function(input, output) {
  load(url("https://raw.githubusercontent.com/aml4td/website/main/RData/forested_data.RData"))
  
  percip <- 
    forested_train %>% 
    mutate(annual_precipitation = log10(`annual precipitation`))
  
  percip_bin <- 
    percip %>% 
    select(class, annual_precipitation) %>% 
    mutate(percip_bin = ntile(annual_precipitation, 50)) %>% 
    summarize(
      rate = mean(class == "Yes"),
      percip = median(annual_precipitation),
      n = length(annual_precipitation),
      .by = c(percip_bin)
    ) %>% 
    mutate(logit = binomial()$linkfun(rate))
  
  percip_rng <- extendrange(percip_bin$percip)
  # percip_rng[1] <- 0.0
  
  percip_grid <- tibble(annual_precipitation = seq(percip_rng[1], percip_rng[2], length.out = 100))
  
  linear_fit <- 
    logistic_reg() %>% 
    fit(class ~ annual_precipitation, data = percip)
  
  linear_pred <- 
    augment(linear_fit, new_data = percip_grid) %>% 
    mutate(Model = "Linear Term", group = "fit_linear")
  
  num_spline <- 9
  spline_fit <- 
    logistic_reg() %>% 
    fit(class ~ naturalSpline(annual_precipitation, df = num_spline), data = percip)
  
  spline_lab <- paste0("Natural Splines (", num_spline, " df)")
  
  spline_pred <- 
    augment(spline_fit, new_data = percip_grid) %>% 
    mutate(Model = spline_lab, group = "fit_spline")
  
  gam_fit <- 
    gen_additive_mod() %>% 
    set_mode("classification") %>% 
    fit(class ~ s(annual_precipitation), data = percip)
  gam_lab <- paste0("GAM (", round(sum(gam_fit$fit$edf[-1]), 1), " df)")
  
  gam_pred <- 
    augment(gam_fit, new_data = percip_grid) %>% 
    mutate(Model = gam_lab, group = "fit_gam")
  
  predictions <- 
    bind_rows(linear_pred, spline_pred, gam_pred) %>% 
    mutate(Model = factor(Model, levels = c("Linear Term", spline_lab, gam_lab))) %>% 
    mutate(logit = binomial()$linkfun(.pred_Yes))
  
  output$plot <-
    renderPlot({
      
      if (input$yaxis == "rate") {
        p <- 
          percip_bin %>% 
          ggplot(aes(percip)) + 
          labs(x = "Log10 Annual Percipitation", y = "Probability of Forestation") + 
          lims(y = 0:1)
      } else {
        p <- 
          percip_bin %>% 
          ggplot(aes(percip)) + 
          labs(x = "Log10 Annual Percipitation", y = "Logit")
      }
      
      
      if (any(input$include == "Data")) {
        if (input$yaxis == "rate") {
          p <- p +  geom_point(aes(y = rate), alpha = 1 / 3, cex = 3) 
        } else {
          p <- p +  geom_point(aes(y = logit), alpha = 1 / 3, cex = 3) 
        }
      }
      
      if (any(grepl("fit_", input$include))) {
        curve_data <- dplyr::filter(predictions, group %in% input$include)
        
        if (input$yaxis == "rate") {
          p <- p +
            geom_line(data = curve_data, 
                      aes(x = annual_precipitation, y = .pred_Yes, color = Model),
                      linewidth = 1)
        } else {
          p <- p +
            geom_line(data = curve_data, 
                      aes(x = annual_precipitation, y = logit, color = Model),
                      linewidth = 1) 
        }
        
        p <- p + 
          theme(legend.position = "top") + 
          scale_color_brewer(drop = FALSE, palette = "Dark2")
      }
      
      p <- p + theme_light_bl()
      print(p)
    }, res = 100)
}

app <- shinyApp(ui = ui, server = server)