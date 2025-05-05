# Requires the sources in shiny-setup.R

ui <- page_fillable(
#	theme = grid_theme,
	padding = "1rem",
	layout_columns(
		fill = FALSE,
		col_widths = breakpoints(xs = c(3, 3, 3, 3), sm = 4),
		column(
			width = 12,
			sliderInput(
				"start",
				label = "Starting Value",
				min = -6,
				max = 10,
				value = 3,
				step = 1
			)
		),
		column(
			width = 12,
			numericInput(
				"rate",
				label = "Leaning Rate",
				min = 0,
				max = 3,
				value = 2,
				step = 0.1
			),
			checkboxInput(
				"decay",
				label = "Decay?",
				value = FALSE
			)
		),
		column(
			width = 12,
			sliderInput(
				"iter",
				label = "Iteration",
				min = 0L,
				max = 50L,
				step = 1L,
				value = 0L,
				width = "100%"
			)
		)
	),
	as_fill_carrier(plotOutput("iterations"))
)

server <- function(input, output) {
	library(ggplot2)
	library(dplyr)

	cyclic <- function(epoch, initial = 0.001, largest = 0.1, step_size = 5) {
		if (largest < initial) {
			tmp <- initial
			largest <- initial
			initial <- tmp
		} else if (largest == initial) {
			initial <- initial / 10
		}
		cycle <- floor(1 + (epoch / 2 / step_size))
		x <- abs((epoch / step_size) - (2 * cycle) + 1)
		initial + (largest - initial) * max(0, 1 - x)
	}
	decay_time <- function(epoch, initial = 0.1, decay = 1) {
		initial / (1 + decay * epoch)
	}

	fn <- function(x) x * cos(.5 * x)
	# D(quote(x * cos(.5 * x)), "x")
	deriv_1 <- function(x) cos(0.5 * x) - x * (sin(0.5 * x) * 0.5)

	# ------------------------------------------------------------------------------

	max_iter <- 50
	mx <- max_iter + 1

	x_seq <- seq(-10, 10, length.out = 1000)
	y_seq <- fn(x_seq)

	# ------------------------------------------------------------------------------

	p_base <- dplyr::tibble(x = x_seq, y = y_seq) %>%
		ggplot(aes(x, y)) +
		geom_line(linewidth = 1, alpha = 1 / 4) +
		labs(x = "Parameter", y = "Objective Function") +
		theme_bw()

	output$iterations <- renderPlot(
		{
			x_cur <- input$start
			res <- dplyr::tibble(x = rep(NA, mx), y = rep(NA, mx), iter = 0:max_iter)
			res$x[1] <- x_cur
			res$y[1] <- fn(x_cur)

			if (input$iter >= 1) {
				for (i in 1:input$iter) {
					if (input$decay) {
						# rate <- cyclic(i, initial = input$rate / 2, largest = input$rate)
						rate <- decay_time(i - 1, initial = input$rate, decay = 1)
					} else {
						rate <- input$rate
					}

					x_new <- x_cur - rate * deriv_1(x_cur)
					y_new <- fn(x_new)
					res$x[i + 1] <- x_new
					res$y[i + 1] <- y_new
					x_cur <- x_new
				}
				deriv_val <- deriv_1(x_cur) # for printing
			}
			# start 3, lr 2 is good example
			p <- p_base +
				geom_point(
					data = res %>% filter(x >= -10 & x <= 10),
					aes(col = y),
					show.legend = FALSE,
					cex = 2,
					alpha = 3 / 4
				) +
				geom_vline(xintercept = x_cur, col = "black", lty = 3) +
				geom_rug(
					data = res %>% filter(x >= -10 & x <= 10),
					aes(x = x, y = NULL, col = y),
					alpha = 1 / 2,
					show.legend = FALSE
				) +
				scale_color_viridis_c(
					option = "plasma",
					breaks = 0:max_iter,
					limits = extendrange(y_seq)
				)

			if (input$iter > 0) {
				lbl <- paste("gradient:", signif(deriv_val, digits = 3))
				if (input$decay) {
					lbl <- paste0(lbl, ", learning rate:", signif(rate, digits = 3))
				}
			} else {
				lbl <- "initial guess"
			}
			p <- p + labs(title = lbl)

			print(p)
		},
		res = 100
	)
}

app <- shinyApp(ui, server)
