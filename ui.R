library(shiny)
library(bslib)
library(plotly)
library(shinyWidgets)

vis_count = value_box(
  title = "Total visitors",
  value = textOutput("vis_count") %>% shinycssloaders::withSpinner(type = 7),
  showcase = plotlyOutput("vis_count_plot"),
  showcase_layout = "bottom"
)

vis_clicks = value_box(
  title = "Average clicks per user",
  value = textOutput("click_count") %>% shinycssloaders::withSpinner(type = 7),
  showcase = plotlyOutput("click_count_plot"),
  showcase_layout = "bottom"
)

vis_duration = value_box(
  title = "Average time used",
  value = textOutput("duration") %>% shinycssloaders::withSpinner(type = 7),
  showcase = plotlyOutput("duration_plot"),
  showcase_layout = "bottom"
)

ui = page_sidebar(
  window_title = "CRAFT Dashboard Analytics",
  title = layout_columns(
    tags$img(src = "craftlogo.gif", style = "height: 3rem; vertical-align: top;"),
    span("CRAFT Dashboard Analytics"),
    # span(input_dark_mode(id = "theme"), style = "padding-left: 50px;"),
    radioGroupButtons(
      inputId = "duration_selector",
      label = NULL,
      choices = c("24h" = 60*60*24, "7d" = 60*60*24*7, "30d" = 60*60*24*30, "All time" = 0),
      selected = 60*60*24*7,
      status = "info"
    ),
    col_widths = c(1, 4, 7)
  ),
  theme = bs_theme(bootswatch = bootswatch),
  sidebar = sidebar(open = F),
  layout_columns(
    layout_column_wrap(
      vis_count,
      vis_clicks,
      vis_duration,
      width = 1
    ),
    plotOutput("weekly_heatmap"),
    col_widths = c(4, 8)
  )
)
