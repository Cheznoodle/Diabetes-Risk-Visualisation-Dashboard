# Diabetes-Risk-Visualization-Dashboard

An interactive R Shiny dashboard that lets you explore a 100,000-patient diabetes dataset through six linked, filterable visualisations — built to make patterns in age, BMI, smoking history, and clinical markers easy to see and easy to question.

## Overview
 
This project turns a static diabetes prediction dataset into an interactive analytical tool. Instead of a fixed set of charts, the app is built around a single reactive pipeline: a user picks a plot type and a set of filters (age range, gender, diabetes status), and every chart, cluster, and correlation on screen recalculates against that filtered slice of the data in real time.
 
The goal was to practice the full small-scale analytics workflow — cleaning messy real-world categorical data, doing exploratory analysis, applying an unsupervised learning method (k-means clustering), and packaging the result as something a non-technical person could actually click through — rather than just producing a one-off notebook of static plots.

## Why this project
 
Diabetes prevalence and its risk factors (BMI, hypertension, heart disease, smoking, HbA1c, blood glucose) are widely discussed but rarely explored interactively outside of academic papers or fixed dashboards. This project asks a simple question: *if you hand a filterable version of this data to someone, what do they notice?* It was built as coursework but designed to double as a portfolio piece demonstrating data cleaning, exploratory data analysis (EDA), a basic clustering model, and interactive dashboard engineering in R.

## Dataset
 
- **File:** `diabetes_prediction_dataset.csv`
- **Size:** 100,000 patient records, 9 columns
- **Source:** https://www.kaggle.com/datasets/iammustafatz/diabetes-prediction-dataset

| Column | Type | Description |
|---|---|---|
| `gender` | categorical | Female / Male / Other |
| `age` | numeric | Patient age (0.08–80 years) |
| `hypertension` | binary (0/1) | Whether the patient has hypertension |
| `heart_disease` | binary (0/1) | Whether the patient has heart disease |
| `smoking_history` | categorical | Smoking status (raw values include inconsistent labels like `"Former Smoker"` / `"never"` / `"No Info"`, cleaned in-app — see below) |
| `bmi` | numeric | Body Mass Index |
| `HbA1c_level` | numeric | Glycated haemoglobin level, a marker of blood sugar over ~3 months |
| `blood_glucose_level` | numeric | Blood glucose reading |
| `diabetes` | binary (0/1) | Target label: diabetes diagnosis |

## Project process
 
1. **Data cleaning** — dropped missing values and duplicate rows, then standardised the `smoking_history` column, which arrived with inconsistent labels (e.g. `"Former Smoker"`, `"Not Currently Smoking"`, `"No Info"`) that were remapped to a consistent, lowercase set of categories.
2. **Feature engineering for exploration** — converted `diabetes`, `hypertension`, and `heart_disease` into factors, and derived a combined `panel_label` (e.g. *"Hypertension, No Heart Disease"*) so the age-distribution view can facet by comorbidity combination without extra UI complexity.
3. **Exploratory analysis** — built six exploratory views (below) to look at the target variable from different angles: demographic (age, gender), behavioural (smoking), physiological (BMI), and relational (correlation between all numeric variables).
4. **Unsupervised segmentation** — applied **k-means clustering** (k=3) on BMI and hypertension to segment patients into Low / Medium / High risk groups, with clusters ordered by centroid BMI so the labels are consistent every time the app reruns (not just arbitrary cluster IDs).
5. **Interactive dashboard build** — wrapped everything in a Shiny app with reactive filtering, so every plot responds live to age range, gender, and diabetes-status filters, and users can download the current plot as a PNG.
6. **Performance handling** — added a sampling step (20% sample when a filtered subset exceeds 1,000 rows) so the interactive plots stay responsive against a 100k-row dataset rather than trying to render every point.
## Dashboard features
 
The app has two control panels (Plot Selection and Filters) and one main plotting area, all built with `plotly` so every chart is zoomable and hoverable.
 
| Plot type | What it shows |
|---|---|
| **Age Distribution** | Histogram of age vs. diabetes status, faceted by hypertension/heart-disease combination, with an adjustable bin count |
| **Smoking History** | Proportion of diabetes cases across smoking categories (stacked bar) |
| **BMI Distribution** | Density plot comparing BMI distributions for diabetic vs. non-diabetic patients |
| **High-Risk Clusters** | K-means clustering (k=3) on BMI and hypertension, labelled Low/Medium/High Risk and plotted against smoking history |
| **Gender Differences** | Proportion of diabetes cases by gender |
| **Correlation Heatmap** | Correlation matrix across all numeric variables, rendered as an interactive heatmap |
 
**Shared controls:**
- Age range slider
- Gender filter (Both / Female / Male / Other)
- Diabetes status filter (where applicable to the selected plot)
- Download-as-PNG button for the currently displayed chart
## What the data shows
 
A few patterns that fall out of the raw dataset (computed directly from the CSV, not model predictions):
 
- **Overall prevalence:** 8.5% of the 100,000 records are labelled diabetic (8,500 cases).
- **BMI gap:** diabetic patients average a BMI of **31.99** vs. **26.89** for non-diabetic patients.
- **HbA1c gap:** diabetic patients average an HbA1c of **6.93** vs. **5.40** for non-diabetic patients — consistent with HbA1c being a standard diagnostic marker.
- **Blood glucose gap:** diabetic patients average **194.09** vs. **132.85** for non-diabetic patients.
- **Smoking data quality:** roughly 36% of records have no smoking history recorded (`"No Info"`), which is worth keeping in mind when interpreting the Smoking History view — it's a real limitation of the source data, not something the cleaning step could recover.
These are descriptive patterns in the dataset, not causal claims — the dashboard is an exploration tool, not a diagnostic one.
 
## Tech stack
 
- **Language:** R
- **Web framework:** [Shiny](https://shiny.posit.co/)
- **Data wrangling:** `dplyr`
- **Visualization:** `ggplot2`, `plotly` (via `ggplotly()` for interactivity), `shinythemes`, `shinycssloaders`
- **Modelling:** base R `kmeans()` for clustering
## Project structure
 
```
diabetes-risk-visualization-dashboard/
├── app.R                          # Shiny app: data cleaning, UI, and server logic
├── diabetes_prediction_dataset.csv # Source dataset (100,000 rows)
├── README.md
├── .gitignore
```
 
## Getting started
 
### Prerequisites
- [R](https://cran.r-project.org/) (4.0+) and [RStudio](https://posit.co/download/rstudio-desktop/)
### Installation
 
1. Clone the repo:
```bash
   git clone https://github.com/<your-username>/diabetes-risk-visualization-dashboard.git
   cd diabetes-risk-visualization-dashboard
```
2. Install the required R packages:
```r
   install.packages(c("shiny", "shinythemes", "shinycssloaders",
                       "ggplot2", "dplyr", "plotly", "cluster"))
```
3. Run the app (from R or RStudio, with the working directory set to the repo folder):
```r
   shiny::runApp("app.R")
```
   The dashboard will open in your default browser (or the RStudio Viewer pane).
 
## Design decisions & trade-offs
 
- **k-means over a supervised model:** the brief here was exploratory segmentation, not prediction, so an unsupervised approach (k-means on BMI + hypertension) was used to surface a simple risk grouping rather than building and validating a classifier.
- **Sampling large filtered views:** rather than rendering all rows when a filter selection still leaves >1,000 records, the app takes a 20% sample to keep the interactive `plotly` charts responsive. This trades a small amount of precision for a dashboard that doesn't lag.
- **Cluster labels ordered by centroid:** k-means cluster numbers are arbitrary on each run, so cluster centroids are sorted by BMI and relabelled Low/Medium/High Risk — this keeps the labelling meaningful and consistent rather than randomly assigning "Cluster 1/2/3".
