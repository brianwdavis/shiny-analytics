library(shiny)
library(DBI)
library(dplyr)
library(plotly)
library(shinyWidgets)
library(stringr)
library(lubridate)



server <- function(input, output, session) {
  con = make_connection(dstadmin_creds)
  #on.exit(DBI::dbDisconnect(con))
  
  start_time = reactive({
    d = as.numeric(input$duration)
    if (d > 0) {
      Sys.time() - d
    } else {
      lubridate::as_datetime(0)
    }
  }) %>% 
    bindEvent(input$duration)
  
  unique_vis = reactive({
    start_time = start_time()
    tbl(con, "event_log") %>% 
      filter(type == "login") %>% 
      filter(time > start_time) %>% 
      collect()
  })
  
  output$vis_count = renderText({
    nrow(unique_vis())
  })
  
  output$vis_count_plot = renderPlotly({
    unique_vis() %>% 
      mutate(time = lubridate::floor_date(time, "hours")) %>% 
      group_by(time) %>% 
      tally() %>% 
      plot_ly(
        x = ~time,
        y = ~n
      ) %>% 
      add_lines(
        fill = 'tozeroy'
      ) %>% 
      plotly::layout(
        xaxis = list(visible = T, showgrid = F, title = "", fixedrange = T),
        yaxis = list(visible = F, showgrid = F, title = "", fixedrange = T),
        hovermode = "x",
        margin = list(t = 0, r = 0, l = 0, b = 0),
        font = list(color = "white"),
        paper_bgcolor = "transparent",
        plot_bgcolor = "transparent"
      ) %>%
      plotly::config(displayModeBar = F)
  })
  
  per_vis_stats = reactive({
    start_time = start_time()
    
    tbl(con, "event_log") %>% 
      filter(time > start_time) %>% 
      mutate(time_num = sql('EXTRACT(EPOCH FROM "time")')) %>% 
      filter(!str_detect(as.character(details), "plotly|navset")) %>% 
      group_by(session) %>% 
      summarise(
        n = count(session),
        len = max(time_num) - min(time_num),
        arrival = min(time)
      ) %>% 
      collect() %>% 
      mutate(arrival = lubridate::with_tz(arrival, "America/New_York"))
  }) %>% 
    bindEvent(input$duration)
  
  output$click_count = renderText({
    round(mean(per_vis_stats()$n), 1)
  })
  
  output$click_count_plot = renderPlotly({
    plot_ly(
      data = per_vis_stats(),
      x = ~n,
      type = "histogram"
    ) %>% 
      plotly::layout(
        xaxis = list(visible = T, showgrid = F, title = "", fixedrange = T),
        yaxis = list(visible = F, showgrid = F, title = "", fixedrange = T),
        hovermode = "x",
        margin = list(t = 0, r = 0, l = 0, b = 0),
        font = list(color = "white"),
        paper_bgcolor = "transparent",
        plot_bgcolor = "transparent"
      ) %>%
      plotly::config(displayModeBar = F)
  })
  
  output$duration = renderText({
    ret = per_vis_stats() %>% 
      filter(len < 30*60) %>%
      pull(len) %>% 
      mean() 
    paste0(ret %/% 60, "m ", round(ret %% 60, 1), "s")
  })
  
  output$duration_plot = renderPlotly({
    plot_ly(
      data = per_vis_stats() %>% 
        filter(len < 30*60),
      x = ~len,
      type = "histogram"
    ) %>% 
      plotly::layout(
        xaxis = list(visible = T, showgrid = F, title = "", fixedrange = T),
        yaxis = list(visible = F, showgrid = F, title = "", fixedrange = T),
        hovermode = "x",
        margin = list(t = 0, r = 0, l = 0, b = 0),
        font = list(color = "white"),
        paper_bgcolor = "transparent",
        plot_bgcolor = "transparent"
      ) %>%
      plotly::config(displayModeBar = F)
  })
  
  output$weekly_heatmap = renderPlot({
    per_vis_stats() %>% 
      mutate(
        x = wday(arrival, week_start = 1), 
        y = hour(arrival) + 0.5
      ) %>% 
      group_by(x, y) %>% 
      summarize(ct = length(arrival)) %>% 
      ggplot(aes(x = x, y = y)) +
      geom_tile(aes(fill = ct)) +
      scale_fill_viridis_c(end = 0.85) +
      scale_y_reverse(
        limits = c(24, 0),
        expand = c(0, 0),
        breaks = (0:12)*2,
        labels = function(br) {
          b = br %% 12
          ampm = c("AM", "PM")[(br %/% 12) + 1]
          l = paste0(b, ":00", ampm)
          l[b == 0] <- c("Midnight", "Noon", "Midnight")
          l
          }
      ) +
      scale_x_continuous(
        labels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"),
        limits = c(0.5, 7.5),
        breaks = 1:7,
        expand = c(0,0)
      ) +
      labs(x = NULL, y = NULL, fill = "Users per typical hour") +
      theme_minimal(base_size = 18) +
      theme(
        legend.position = "top", 
        legend.key.width = unit(1, "in"),
        panel.grid.major.x = element_blank()
        ) 
  })
}