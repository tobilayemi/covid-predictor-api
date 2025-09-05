# COVID-19 Prediction Project

This project explores predictive modeling for COVID-19 risk analysis using real-world inspired data provided by **eHealth Africa**.  
The dataset contains COVID-19 case information from the town of *Hocus Pocus*, with multiple factors that may determine infection likelihood.  

## Project Workflow
1. **Data Collection & Preparation** – Cleaned and structured raw case data.  
2. **Exploratory Data Analysis (EDA)** – Identified patterns and relationships between variables.  
3. **Feature Engineering** – Created meaningful features to improve model performance.  
4. **Modeling** – Tested machine learning algorithms including:
   - Logistic Regression  
   - Decision Trees  
   - Random Forests  
   - Gradient Boosting Machines  
   - Ensemble methods for accuracy improvement  
5. **Training & Validation** – Applied cross-validation and hyperparameter tuning to avoid overfitting.  
6. **Evaluation** – Compared models using metrics:
   - Accuracy  
   - Precision  
   - Recall  
   - F1 Score  
   - AUC-ROC  
7. **Deployment** – Exposed the best-performing model through a **Plumber API** in R, with a simple **HTML frontend** for user interaction.  
8. **Visualization** – Built outputs for interpreting model results. 


##  How to Run the Project  

### 1. Clone the Repository
git clone https://github.com/YOUR-USERNAME/covid-predictor-api.git
cd covid-predictor-api

### 2. Install Required R Packages
Open R or RStudio and install dependencies:

install.packages(c("tidyverse", "lubridate", "tidymodels", 
                   "themis", "janitor", "vip", "ggplot2", 
                   "pROC", "plumber"))
                   
### 3. Train the Model
Run the training script:
check path ("scripts/Covid_predictor.R")
This will save the trained model as model/covid_final_model.rds.

### 4. Start the API
To do this, Run:
check the path ("scripts/run.R")
The API will start at:
http://127.0.0.1:21512

### 5. To Use the Frontend
Open http://127.0.0.1:21512/index.html in a browser.
It connects to the API and allows you to test predictions.


## Author
Oluwatobi Olatunbosun
adebukolaoluwatobi@gmail.com



