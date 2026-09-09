# Adapted from https://emilhvitfeldt.com/post/claude-code-alt-text-quarto/

library(shiny)
library(bslib)

# Extract figure info from all qmd files
extract_figures <- function(base_path) {
  qmd_files <- list.files(base_path, pattern = "[.]qmd$", full.names = TRUE, recursive = TRUE)
  message("Found ", length(qmd_files), " qmd files")

  figures <- list()

  for (qmd_file in qmd_files) {
    chapter <- tools::file_path_sans_ext(basename(qmd_file))
    lines <- readLines(qmd_file, warn = FALSE)

    i <- 1
    while (i <= length(lines)) {
      line <- lines[i]

      # Look for figure labels
      if (grepl("^#[|][ ]*label:[ ]*fig-", line)) {
        label <- trimws(sub("^#[|][ ]*label:[ ]*", "", line))

        # Find fig-cap and fig-alt in the following lines
        fig_cap <- NULL
        fig_alt <- NULL
        j <- i + 1

        while (j <= length(lines) && grepl("^#[|]", lines[j])) {
          if (grepl("^#[|][ ]*fig-cap:", lines[j])) {
            # Capture multiline fig-cap
            cap_lines <- sub("^#[|][ ]*fig-cap:[ ]*[|]?[ ]*", "", lines[j])
            if (cap_lines == "" || cap_lines == "|") {
              # Multiline format
              j <- j + 1
              cap_content <- c()
              while (j <= length(lines) && grepl("^#[|][ ]{2,}", lines[j])) {
                cap_content <- c(cap_content, trimws(sub("^#[|][ ]+", "", lines[j])))
                j <- j + 1
              }
              fig_cap <- paste(cap_content, collapse = " ")
              j <- j - 1
            } else {
              fig_cap <- trimws(cap_lines)
            }
          } else if (grepl("^#[|][ ]*fig-alt:", lines[j])) {
            # Capture multiline fig-alt
            alt_lines <- sub("^#[|][ ]*fig-alt:[ ]*[|]?[ ]*", "", lines[j])
            if (alt_lines == "" || alt_lines == "|") {
              # Multiline format
              j <- j + 1
              alt_content <- c()
              while (j <= length(lines) && grepl("^#[|][ ]{2,}", lines[j])) {
                alt_content <- c(alt_content, trimws(sub("^#[|][ ]+", "", lines[j])))
                j <- j + 1
              }
              fig_alt <- paste(alt_content, collapse = " ")
              j <- j - 1
            } else {
              fig_alt <- trimws(alt_lines)
            }
          }
          j <- j + 1
        }

        # Find the image file
        img_path <- file.path(
          base_path, ".quarto", "_freeze", chapter,
          "figure-html", paste0(label, "-1.png")
        )

        img_exists <- file.exists(img_path)

        if (!is.null(fig_alt) && nchar(fig_alt) > 0 && img_exists) {
          figures[[length(figures) + 1]] <- list(
            chapter = chapter,
            label = label,
            fig_cap = if (is.null(fig_cap) || nchar(fig_cap) == 0) "(no caption)" else fig_cap,
            fig_alt = fig_alt,
            img_path = img_path,
            file_path = qmd_file,
            line_number = i
          )
        }
      }
      i <- i + 1
    }
  }

  message("Found ", length(figures), " figures with alt text and images")
  figures
}

# Get figures
base_path <- "/Users/max/content/website/"
figures <- extract_figures(base_path)

ui <- page_sidebar(
  title = "Alt Text Verification",
  sidebar = sidebar(
    width = 300,
    selectInput(
      "chapter_filter",
      "Filter by Chapter",
      choices = c("All", sort(unique(sapply(figures, `[[`, "chapter")))),
      selected = "All"
    ),
    hr(),
    uiOutput("figure_list")
  ),
  card(
    card_header(
      div(
        style = "display: flex; justify-content: space-between; align-items: center;",
        textOutput("current_label"),
        uiOutput("file_link")
      )
    ),
    layout_columns(
      col_widths = c(6, 6),
      card(
        card_header("Image"),
        imageOutput("figure_image", height = "auto")
      ),
      card(
        card_header("Alt Text"),
        div(
          style = "padding: 1rem;",
          h5("Caption:"),
          div(style = "background: #f8f9fa; padding: 0.75rem; border-radius: 4px; margin-bottom: 1rem;",
            textOutput("fig_cap")
          ),
          h5("Alt Text:"),
          div(style = "background: #f8f9fa; padding: 0.75rem; border-radius: 4px; white-space: pre-wrap; word-wrap: break-word;",
            textOutput("fig_alt")
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {

  filtered_figures <- reactive({
    if (input$chapter_filter == "All") {
      figures
    } else {
      Filter(function(x) x$chapter == input$chapter_filter, figures)
    }
  })

  output$figure_list <- renderUI({
    figs <- filtered_figures()
    if (length(figs) == 0) return(p("No figures found"))

    choices <- setNames(
      seq_along(figs),
      sapply(figs, function(x) paste0(x$chapter, ": ", x$label))
    )

    radioButtons(
      "selected_fig",
      "Select Figure",
      choices = choices,
      selected = 1
    )
  })

  current_figure <- reactive({
    req(input$selected_fig)
    figs <- filtered_figures()
    idx <- as.integer(input$selected_fig)
    if (idx > 0 && idx <= length(figs)) {
      figs[[idx]]
    } else {
      NULL
    }
  })

  output$current_label <- renderText({
    fig <- current_figure()
    if (is.null(fig)) return("")
    paste(fig$chapter, "-", fig$label)
  })

  output$file_link <- renderUI({
    fig <- current_figure()
    if (is.null(fig)) return(NULL)

    actionLink(
      "open_file",
      paste0(fig$chapter, ".qmd:", fig$line_number),
      style = "font-size: 0.875rem;"
    )
  })

  observeEvent(input$open_file, {
    fig <- current_figure()
    if (!is.null(fig)) {
      rstudioapi::navigateToFile(fig$file_path, line = fig$line_number)
    }
  })

  output$figure_image <- renderImage({
    fig <- current_figure()
    req(fig)

    list(
      src = fig$img_path,
      contentType = "image/png",
      width = "100%",
      alt = fig$fig_alt
    )
  }, deleteFile = FALSE)

  output$fig_cap <- renderText({
    fig <- current_figure()
    if (is.null(fig)) return("")
    fig$fig_cap
  })

  output$fig_alt <- renderText({
    fig <- current_figure()
    if (is.null(fig)) return("")
    fig$fig_alt
  })
}

shinyApp(ui, server)
