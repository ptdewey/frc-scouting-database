library(tidyverse)
library(dplyr)
library(tibble)

source("api/teamopr.R")
source("model/predict.R")

# Read api key from .env
if (!exists("api_key")) {
    readRenviron(".env")
    api_key <- Sys.getenv("API_KEY")
}

event_key <- "2023vagle"

matches <- subset_played_unplayed(event_key, api_key)

opr_df <- read_csv("output/2023vagle/2023vagle_all.csv")
opr_df <- opr_df[, -1]

out <- get_predictions(matches, opr_df)
write.csv(out, glue("output/{event_key}/{event_key}_predictions.csv"))

