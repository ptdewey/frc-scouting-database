library(tidyverse)
library(magrittr)
library(dplyr)
library(glue)
library(tibble)
library(purrr)
library(stringr)
library(jsonlite)

# local imports
file_sources <- list.files(c("api"), pattern = "\\.R$",
    full.names = TRUE, ignore.case = TRUE)
sapply(file_sources, source)

# Read api key from .env
if (!exists("api_key")) {
    readRenviron(".env")
    api_key <- Sys.getenv("API_KEY")
}

###############


# Get event data for input event key
args <- commandArgs(trailingOnly = TRUE)
if (!exists("event_key")) {
    if (length(args) == 0) {
        event_key <- args[1]
        event_all <- get_event_data(event_key, api_key)
    }
}

# change year as desired
# year <- 2024
year <- substring(Sys.Date(), 1, 4) # or use this for current year

# merge event data
events_df <- get_event_list(year, api_key)
event_keys <- get_filtered_events(events_df)$key
# TEST: Uncomment this for testing once preseason events start
# event_keys <- get_preseason_events(events_df)$key

# PERF: computationally intensive
merged <- get_multi_event_data(events_df, api_key)

# filtere merged data to contain only teams from one event

# CHANGE THIS VARIABLE TO GET FUTURE EVENT DATA:
filtered_keys <- c("2024vagle", "2024vaash")


for (key in filtered_keys) {
    df <- get_filtered_multi_event_data(key, api_key)
}

