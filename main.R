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

# merge event data
year <- 2023
event_keys <- get_filtered_events(get_event_list(year, api_key))$key
merged <- get_multi_event_data(event_keys, api_key)

# filtere merged data to contain only teams from one event

# CHANGE THIS VARIABLE TO GET FUTURE EVENT DATA:
# champs division keys
filtered_keys <- c("2023arc", "2023cur", "2023dal",
    "2023gal", "2023hop", "2023joh", "2023mil"
)
for (key in filtered_keys) {
    df <- get_filtered_multi_event_data(key, api_key)
}

