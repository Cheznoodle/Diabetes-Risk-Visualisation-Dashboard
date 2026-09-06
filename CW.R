# Load necessary libraries for the Shiny app
library(shiny)
library(shinythemes)
library(shinycssloaders)
library(ggplot2)
library(dplyr)
library(plotly)
library(cluster)

# Load and clean the dataset
data <- read.csv("diabetes_prediction_dataset.csv") %>%
  na.omit() %>%
  distinct() %>%
  mutate(
    smoking_history = case_when(
      smoking_history == "Former Smoker" ~ "former",
      smoking_history == "Current Smoker" ~ "current",
      smoking_history == "No Info" ~ "no info",
      smoking_history == "Never Smoked" ~ "never",
      smoking_history == "Not Currently Smoking" ~ "not current",
      TRUE ~ smoking_history
    ),
    diabetes = factor(diabetes, levels = c(0, 1)),
    hypertension = factor(hypertension, levels = c(0, 1)),
    heart_disease = factor(heart_disease, levels = c(0, 1)),
    panel_label = case_when(
      hypertension == 0 & heart_disease == 0 ~ "No Hypertension, No Heart Disease",
      hypertension == 1 & heart_disease == 0 ~ "Hypertension, No Heart Disease",
      hypertension == 0 & heart_disease == 1 ~ "No Hypertension, Heart Disease",
      hypertension == 1 & heart_disease == 1 ~ "Hypertension and Heart Disease"
    )
  )

# Define a color palette for diabetes status
diabetes_colors <- c("0" = "seagreen", "1" = "red")

# Define the User Interface (UI) for the Shiny application
ui <- fluidPage(
  theme = shinytheme("flatly"),
  titlePanel("Diabetes Data Visualization"),
  sidebarLayout(
    sidebarPanel(
      tabsetPanel(
        tabPanel("Plot Selection",
                 selectInput("plot_type", "Choose Plot Type:",
                             choices = c("Age Distribution", "Smoking History", 
                                         "BMI Distribution", "High-Risk Clusters", 
                                         "Gender Differences", "Correlation Heatmap"))
        ),
        tabPanel("Filters",
                 conditionalPanel(
                   condition = "input.plot_type == 'Age Distribution'",
                   sliderInput("age_bins", "Number of Bins:", min = 5, max = 30, value = 15)
                 ),
                 sliderInput("age_range", "Age Range:", min = min(data$age), max = max(data$age), value = range(data$age)),
                 selectInput("gender_filter", "Gender:", choices = c("Both", unique(data$gender)), selected = "Both"),
                 conditionalPanel(
                   condition = "!(input.plot_type == 'Smoking History' || 
                                  input.plot_type == 'Gender Differences' || 
                                  input.plot_type == 'High-Risk Clusters')",
                   selectInput("diabetes_filter", "Diabetes Status:", choices = c("Both", "0", "1"), selected = "Both")
                 )
        )
      ),
      downloadButton("downloadPlot", "Download Plot")
    ),
    mainPanel(
      plotlyOutput("interactivePlot") %>% withSpinner(color = "#34495e")
    )
  )
)

# Define the Server logic for the Shiny application
server <- function(input, output) {
  
  filtered_data <- reactive({
    filtered <- data %>%
      filter(
        age >= input$age_range[1] & age <= input$age_range[2],
        if (input$gender_filter != "Both") gender == input$gender_filter else TRUE,
        if (!("Smoking History" %in% input$plot_type || 
              "Gender Differences" %in% input$plot_type || 
              "High-Risk Clusters" %in% input$plot_type) &&
            input$diabetes_filter != "Both") diabetes == input$diabetes_filter else TRUE
      )
    if (nrow(filtered) > 1000) {
      filtered <- filtered %>% sample_frac(0.2)
    }
    return(filtered)
  })
  
  output$interactivePlot <- renderPlotly({
    validate(need(nrow(filtered_data()) > 0, "No data available for the selected filters."))
    
    plot <- switch(input$plot_type,
                   "Age Distribution" = {
                     ggplot(filtered_data(), aes(x = age, fill = diabetes)) +
                       geom_histogram(position = "dodge", bins = input$age_bins) +
                       facet_wrap(~ panel_label, scales = "free") +
                       scale_fill_manual(values = diabetes_colors) +
                       labs(title = "Age, Hypertension, & Heart Disease vs. Diabetes",
                            x = "Age", y = "Count", fill = "Diabetes") +
                       theme_minimal()
                   },
                   "Smoking History" = {
                     ggplot(filtered_data(), aes(x = smoking_history, fill = diabetes)) +
                       geom_bar(position = "fill") +
                       scale_fill_manual(values = diabetes_colors) +
                       labs(title = "Smoking History vs. Diabetes",
                            x = "Smoking History", y = "Proportion", fill = "Diabetes") +
                       theme_minimal()
                   },
                   "BMI Distribution" = {
                     ggplot(filtered_data(), aes(x = bmi, fill = diabetes)) +
                       geom_density(alpha = 0.6) +
                       scale_fill_manual(values = diabetes_colors) +
                       labs(title = "BMI vs. Diabetes",
                            x = "BMI", y = "Density", fill = "Diabetes") +
                       theme_minimal()
                   },
                   "High-Risk Clusters" = {
                     clustering_data <- filtered_data() %>%
                       select(bmi, smoking_history, hypertension) %>%
                       na.omit()
                     
                     if (nrow(clustering_data) >= 3) {
                       set.seed(12345)
                       kmeans_result <- kmeans(clustering_data %>% select(bmi, hypertension), centers = 3)
                       
                       # Order clusters based on their centroids
                       cluster_centroids <- data.frame(kmeans_result$centers)
                       cluster_order <- order(cluster_centroids$bmi)  # Assuming BMI represents risk level
                       
                       clustering_data$cluster <- factor(
                         kmeans_result$cluster,
                         levels = cluster_order, 
                         labels = c("Low Risk", "Medium Risk", "High Risk")
                       )
                     } else {
                       clustering_data$cluster <- factor(rep(1, nrow(clustering_data)), 
                                                         levels = 1:3, 
                                                         labels = c("Low Risk", "Medium Risk", "High Risk"))
                     }
                     
                     ggplot(clustering_data, aes(x = bmi, y = smoking_history, color = cluster)) +
                       geom_point(size = 3, alpha = 0.7) +
                       scale_color_manual(values = c("green", "orange", "red")) +
                       labs(title = "Clustering of High-Risk Individuals",
                            x = "BMI", y = "Smoking History",
                            color = "Risk Level") +
                       theme_minimal()
                   },
                   "Gender Differences" = {
                     ggplot(filtered_data(), aes(x = gender, fill = diabetes)) +
                       geom_bar(position = "fill") +
                       scale_fill_manual(values = diabetes_colors) +
                       labs(title = "Gender vs. Diabetes",
                            x = "Gender", y = "Proportion", fill = "Diabetes") +
                       theme_minimal()
                   },
                   "Correlation Heatmap" = {
                     numeric_data <- filtered_data() %>% select_if(is.numeric)
                     correlation_matrix <- cor(numeric_data, use = "complete.obs")
                     plot_ly(
                       z = correlation_matrix, 
                       type = "heatmap", 
                       x = colnames(correlation_matrix), 
                       y = rownames(correlation_matrix),
                       colors = colorRamp(c("red", "white", "blue"))
                     ) %>%
                       layout(
                         title = list(text = "Correlation Matrix Heatmap", x = 0.5),
                         xaxis = list(title = "Variables"),
                         yaxis = list(title = "Variables")
                       )
                   }
    )
    
    if (inherits(plot, "gg")) {
      ggplotly(plot)
    } else {
      plot
    }
  })
  
  output$downloadPlot <- downloadHandler(
    filename = function() { paste(input$plot_type, "plot.png", sep = "_") },
    content = function(file) {
      plot <- switch(input$plot_type,
                     "Correlation Heatmap" = {
                       numeric_data <- filtered_data() %>% select_if(is.numeric)
                       correlation_matrix <- cor(numeric_data, use = "complete.obs")
                       plot_ly(
                         z = correlation_matrix, 
                         type = "heatmap", 
                         x = colnames(correlation_matrix), 
                         y = rownames(correlation_matrix),
                         colors = colorRamp(c("red", "white", "blue"))
                       ) %>%
                         layout(
                           title = list(text = "Correlation Matrix Heatmap", x = 0.5),
                           xaxis = list(title = "Variables"),
                           yaxis = list(title = "Variables")
                         )
                     },
                     {
                       ggplot(filtered_data(), aes(x = age, fill = diabetes)) +
                         geom_histogram(position = "dodge", bins = input$age_bins)
                     })
      
      if (inherits(plot, "gg")) {
        ggsave(file, plot = plot, device = "png")
      } else if (inherits(plot, "plotly")) {
        plotly::save_image(plot, file = file)
      } else {
        stop("Unsupported plot type for download.")
      }
    }
  )
}

shinyApp(ui = ui, server = server)
