library(plumber)
library(here)

pr <- plumb(here("scripts", "Plumber.R"))
pr$run(port = 21512)

