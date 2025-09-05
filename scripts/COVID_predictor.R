# Oluwatobi Olatunbosun - Senior Cordinator, Data Science
# Loading required libraries

library(tidyverse)    
library(lubridate)    
library(tidymodels)   
library(themis)       
library(janitor)      
library(vip)
library(ggplot2)
library(pROC)
library(plumber)

# Load the dataset
covid_data <- read_csv("data/COVID19 - COVID19.csv")

# Clean up the column names
covid_data <- clean_names(covid_data)

names(covid_data)


# Preprocess the data -----------------------------------------------------
# Preprocessing data is a crucial step before modeling. It involves dropping rows missingvalues
#convert target variable to factor, creating new features, encoding categorical variables, and handling missing values.

covid_clean <- covid_data %>%
  filter(result %in% c("POSITIVE", "NEGATIVE")) %>%
  mutate(
    result = as.factor(result),
    age = year(today()) - birth_year
  ) %>%
  # Convert YES/NO columns to 1/0, but skip 'sex'
  mutate(across(
    where(is.character) & !matches("sex"),
    ~ case_when(
      . == "YES" ~ 1,
      . == "NO" ~ 0,
      TRUE ~ 0
    ),
    .names = "{.col}"
  )) %>%
  # Handle sex separately
  mutate(sex = case_when(
    sex == "MALE" ~ 1,
    sex == "FEMALE" ~ 0,
    TRUE ~ NA_real_
  )) %>%
  select(-birth_year, -specify_other_complications) %>%
  mutate(age = ifelse(is.na(age), median(age, na.rm = TRUE), age))

#Please note that I added age as a new column because it is a clinically meaningful feature whixh helps in interpretation of results and eventually improves model stability

# Final check
glimpse(covid_clean)


# Exploratory Data Analysis (EDA)


# 1. Distribution of COVID-19 Results
result_distribution_plot <- ggplot(covid_clean, aes(x = result, fill = result)) +
  geom_bar() +
  labs(title = "Distribution of COVID-19 Test Results", x = "Test Result", y = "Count") +
  theme_minimal() +
  scale_fill_brewer(palette = "Set1")

#print plot
result_distribution_plot

# 2. Age Distribution by Test Result
age_distribution_plot <- ggplot(covid_clean, aes(x = age, fill = result)) +
  geom_histogram(binwidth = 5, position = "identity", alpha = 0.6) +
  labs(title = "Age Distribution by COVID-19 Test Result", x = "Age", y = "Count") +
  theme_minimal() +
  scale_fill_brewer(palette = "Set1")
#print plot
age_distribution_plot



# Model Training and Evaluation 


# Split the data into training (70%) and testing (30%) sets
set.seed(42) # for reproducibility
covid_split <- initial_split(covid_clean, prop = 0.70, strata = result)
covid_train <- training(covid_split)
covid_test <- testing(covid_split)

# Pre modelling steps
covid_recipe <- recipe(result ~ ., data = covid_train) %>%
  step_mutate(sex = factor(sex)) %>%                
  step_impute_mode(all_nominal_predictors()) %>%    
  step_impute_median(all_numeric_predictors()) %>%  
  step_dummy(all_nominal_predictors()) %>%          
  step_zv(all_predictors())                         



# Defining the model to be trained.

# 1. Logistic Regression
lr_model <- logistic_reg() %>%
  set_engine("glm") %>%
  set_mode("classification")

# 2. Random Forest
rf_model <- rand_forest() %>%
  set_engine("randomForest") %>%
  set_mode("classification")

# Workflow
lr_workflow <- workflow() %>%
  add_recipe(covid_recipe) %>%
  add_model(lr_model)

rf_workflow <- workflow() %>%
  add_recipe(covid_recipe) %>%
  add_model(rf_model)

# Train the Models
lr_fit <- fit(lr_workflow, data = covid_train)

rf_fit <- fit(rf_workflow, data = covid_train)

# Model Evaluation
covid_metrics <- metric_set(accuracy, precision, recall, f_meas, roc_auc)

# Evaluate Logistic Regression
lr_results <- predict(lr_fit, covid_test) %>%
  bind_cols(predict(lr_fit, covid_test, type = "prob")) %>%
  bind_cols(covid_test %>% select(result)) %>%
  covid_metrics(truth = result, estimate = .pred_class, .pred_POSITIVE)

# Evaluate Random Forest
rf_results <- predict(rf_fit, covid_test) %>%
  bind_cols(predict(rf_fit, covid_test, type = "prob")) %>%
  bind_cols(covid_test %>% select(result)) %>%
  covid_metrics(truth = result, estimate = .pred_class, .pred_POSITIVE)

# Compare perfomrmance of both models
print(lr_results)

print(rf_results)


# Select Best 
best_model <- ifelse(mean(rf_results$.estimate) > mean(lr_results$.estimate),
                     "rf", "lr")
best_model


# Based on the results, both models achieved similar accuracy (92%), precision (92%), recall (approx 100%), and F1 (0.96). However, the Random Forest performed slightly better than Logistic Regression in terms of ROC AUC (0.463 vs. 0.350)

final_fit <- if (best_model == "rf") rf_fit else lr_fit
saveRDS(final_fit, "model/covid_final_model.rds")


# Visualizations 
# ROC Curve
rf_probs <- predict(rf_fit, covid_test, type = "prob")$.pred_POSITIVE
lr_probs <- predict(lr_fit, covid_test, type = "prob")$.pred_POSITIVE
rf_roc <- roc(covid_test$result, rf_probs, levels = c("NEGATIVE","POSITIVE"))
lr_roc <- roc(covid_test$result, lr_probs, levels = c("NEGATIVE","POSITIVE"))
plot(rf_roc, col = "blue", main = "ROC Curves")
lines(lr_roc, col = "red")
legend("bottomright", legend = c("RF","LR"), col = c("blue","red"), lwd = 2)

# Confusion Matrix for best model
preds <- predict(final_fit, covid_test) %>% bind_cols(covid_test)
conf_mat(preds, truth = result, estimate = .pred_class) %>% autoplot()

# Feature importance (for RF only)
if (best_model == "rf") {
  rf_fit %>% extract_fit_parsnip() %>% vip() +
    labs(title = "Feature Importance - Random Forest")
}


