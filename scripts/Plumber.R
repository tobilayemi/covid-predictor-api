library(plumber)
library(tidyverse)
library(tidymodels)
library(here)
library(recipes)


#* @filter cors
function(req, res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type")
  
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$status <- 200
    return(list(msg = "ok"))
  }
  
  forward()
}



model <- readRDS(here::here("model", "covid_final_model.rds"))

#* @apiTitle COVID-19 Prediction API

#* Health check
#* @get /health
function() {
  list(status = "ok")
}

#* Predict COVID probability (JSON body)
#* @post /predict
#* @serializer unboxedJSON
function(req, res){
  body <- tryCatch(
    jsonlite::fromJSON(req$postBody, simplifyDataFrame = TRUE),
    error = function(e) NULL
  )
  
  if (is.null(body)) {
    res$status <- 400
    return(list(error = "Invalid JSON. Send application/json POST body."))
  }
  
  newdata <- as_tibble(body) %>% 
    mutate(across(everything(), as.numeric))
  
 
  recipe_obj <- workflows::extract_recipe(model)
  predictors <- recipe_obj$var_info$variable
  
  
  needed <- setdiff(predictors, names(newdata))
  for (col in needed) newdata[[col]] <- 0
  
 
  probs <- predict(model, newdata, type = "prob") %>% pull(.pred_POSITIVE)
  classes <- predict(model, newdata) %>% pull(.pred_class)
  
  tibble(prediction = classes, probability = probs)
}

#* Serve index.html at root
#* @get /index.html
#* @serializer html
function() {
  path <- here("www", "index.html")
  if (!file.exists(path)) {
    stop("index.html not found in www/ folder")
  }
  htmltools::HTML(paste(readLines(path), collapse = "\n"))
}
