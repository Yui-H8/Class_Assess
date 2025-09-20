# Copy this code into server.R file
# Install and import required libraries
require(shiny)
require(ggplot2)
require(leaflet)
require(tidyverse)
require(httr)
require(scales)
# Import model_prediction R which contains methods to call OpenWeather API
# and make predictions
source("model_prediction.R")


test_weather_data_generation<-function(){
  city_weather_bike_df<-generate_city_weather_bike_data()
  stopifnot(length(city_weather_bike_df)>0)
  print(head(city_weather_bike_df))
  return(city_weather_bike_df)
}

# Create a RShiny server
shinyServer(function(input, output){
  # Define a city list
  
  # Define color factor
  color_levels <- colorFactor(c("green", "yellow", "red"), 
                              levels = c("small", "medium", "large"))
  # Test generate_city_weather_bike_data() function
  city_weather_bike_df <- generate_city_weather_bike_data()
  
  # Create another data frame called `cities_max_bike` 
  # with each row contains city location info and max bike
  
    cities_max_bike <- city_weather_bike_df %>%
    group_by(CITY_ASCII) %>%
    filter(BIKE_PREDICTION == max(BIKE_PREDICTION, na.rm = TRUE)) %>%
    slice(1) %>%  
    ungroup() %>%
    select(CITY_ASCII, LAT, LNG, LABEL, BIKE_PREDICTION_LEVEL, DETAILED_LABEL, BIKE_PREDICTION)
  
  output$city_bike_map <- renderLeaflet({
    req(cities_max_bike)
    leaflet(cities_max_bike) %>%
      addTiles() %>%
      addCircleMarkers(
        lng = ~LNG,
        lat = ~LAT,
        radius = ~case_when(
          BIKE_PREDICTION_LEVEL == "small" ~ 6,
          BIKE_PREDICTION_LEVEL == "medium" ~ 10,
          BIKE_PREDICTION_LEVEL == "large" ~ 12,
          TRUE ~ 8
        ),
        color = ~color_levels(BIKE_PREDICTION_LEVEL),  # colorFactor で色を指定
        fillOpacity = 0.8,
        stroke = FALSE,
        popup = ~LABEL
      )
  })
  
  observeEvent(input$city_dropdown, {
    if(input$city_dropdown == "All") {
      leafletProxy("city_bike_map", data = cities_max_bike) %>%
        clearMarkers() %>%
        addCircleMarkers(
          lng = ~LNG,
          lat = ~LAT,
          radius = ~case_when(
            BIKE_PREDICTION_LEVEL == "small" ~ 6,
            BIKE_PREDICTION_LEVEL == "medium" ~ 10,
            BIKE_PREDICTION_LEVEL == "large" ~ 12,
            TRUE ~ 8
          ),
          color = ~color_levels(BIKE_PREDICTION_LEVEL),
          fillOpacity = 0.8,
          stroke = FALSE,
          popup = ~LABEL
        )
    } else {
      selected_data <- cities_max_bike %>% filter(CITY_ASCII == input$city_dropdown)
      leafletProxy("city_bike_map", data = selected_data) %>%
        clearMarkers() %>%
        addCircleMarkers(
          lng = ~LNG,
          lat = ~LAT,
          radius = 12,
          color = "blue",
          fillOpacity = 0.9,
          stroke = TRUE,
          popup = ~DETAILED_LABEL
        )
    }
  })
  
  observeEvent(input$city_dropdown, {
    if (input$city_dropdown == "All") {
      data_to_show <- cities_max_bike
      # If All was selected from dropdown, then render a leaflet map with circle markers
      # and popup weather LABEL for all five cities
      leafletProxy("city_bike_map") %>% 
        clearMarkers() %>%
        addCircleMarkers(
          data = data_to_show,
          lng = ~LNG,
          lat = ~LAT,
          radius = ~case_when(
            BIKE_PREDICTION_LEVEL == "small" ~ 6,
            BIKE_PREDICTION_LEVEL == "medium" ~ 10,
            BIKE_PREDICTION_LEVEL == "large" ~ 12,
            TRUE ~ 8
          ),
          color = ~case_when(
            BIKE_PREDICTION_LEVEL == "small" ~ "green",
            BIKE_PREDICTION_LEVEL == "medium" ~ "yellow",
            BIKE_PREDICTION_LEVEL == "large" ~ "red",
            TRUE ~ "gray"
          ),
          fillOpacity = 0.8,
          stroke = FALSE,
          popup = ~LABEL
        )
    } else {
      # If All was selected from dropdown, then render a leaflet map with circle markers
      # and popup weather LABEL for all five cities
      data_to_show <- cities_max_bike %>% filter(CITY_ASCII == input$city_dropdown)
      leafletProxy("city_bike_map") %>%
        clearMarkers() %>%
        addCircleMarkers(
          data = data_to_show,
          lng = ~LNG,
          lat = ~LAT,
          radius = 12,  
          color = "blue", 
          fillOpacity = 0.9,
          stroke = TRUE,
          popup = ~DETAILED_LABEL 
        )
    }
  })
  
  output$temp_line <- renderPlot({
    if (input$city_dropdown == "All") {
      return(NULL)
    }
    
    selected_city_data <- city_weather_bike_df %>%
      filter(CITY_ASCII == input$city_dropdown)
    
    max_temp <- ceiling(max(selected_city_data$TEMPERATURE, na.rm = TRUE) / 2.5) * 2.5  # 最大値を2.5刻みに丸める
    
    ggplot(selected_city_data, aes(x = as.POSIXct(FORECASTDATETIME), y = TEMPERATURE)) +
      geom_line(color = "steelblue", size = 1) +
      geom_point(color = "red") +
      geom_text(aes(label = round(TEMPERATURE, 1)), vjust = -1, size = 3) +
      scale_x_datetime(
        date_breaks = "12 hours",
        date_labels = "%m/%d %H:%M"
      ) +
      scale_y_continuous(
        breaks = seq(0, max_temp, by = 2.5)
      ) +
      labs(
        title = paste("Temperature Chart", input$city_dropdown),
        x = "Time (3-hour ahead)",
        y = "Temperature (°C)"
      ) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  output$bike_line <- renderPlot({
    if (input$city_dropdown == "All") {
      return(NULL)
    }
    
    selected_city_data <- city_weather_bike_df %>%
      filter(CITY_ASCII == input$city_dropdown)
    
    max_bike <- ceiling(max(selected_city_data$BIKE_PREDICTION, na.rm = TRUE) / 10) * 10
    
    ggplot(selected_city_data, aes(x = as.POSIXct(FORECASTDATETIME), y = BIKE_PREDICTION)) +
      geom_line(color = "darkgreen", size = 1) +
      geom_point(color = "orange", size = 2) +
      geom_text(aes(label = round(BIKE_PREDICTION, 0)), vjust = -1, size = 3) +
      scale_x_datetime(
        date_breaks = "12 hours",
        date_labels = "%m/%d %H:%M"
      ) +
      scale_y_continuous(
        breaks = seq(0, max_bike, by = 500)
      ) +
      labs(
        title = paste("Bike Prediction Trend", input$city_dropdown),
        x = "Time (3-hour ahead)",
        y = "Predicted Bike Demand"
      ) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  output$bike_date_output <- renderText({
    click <- input$plot_click
    if (is.null(click)) {
      return("The information about the clicked point.")
    }
    
    x_val <- as.POSIXct(click$x, origin = "1970-01-01", tz = "UTC")
    y_val <- round(click$y, 1)
    
    paste0("Time = ", format(x_val, "%Y-%m-%d %H:%M"), "\nBike count Pred = ", y_val)
  })
  
  output$humidity_pred_chart <- renderPlot({
    if (input$city_dropdown == "All") {
      return(NULL)
    }
    
    selected_city_data <- city_weather_bike_df %>%
      filter(CITY_ASCII == input$city_dropdown)
    
    ggplot(selected_city_data, aes(x = HUMIDITY, y = BIKE_PREDICTION)) +
      geom_point(color = "purple", size = 2, alpha = 0.6) +
      geom_smooth(method = "lm", formula = y ~ poly(x, 4), color = "blue", se = TRUE) +
      labs(
        title = paste("Humidity vs Bike Demand in", input$city_dropdown),
        x = "Humidity (%)",
        y = "Predicted Bike Demand"
      ) +
      theme_minimal()
  })
  
  
})