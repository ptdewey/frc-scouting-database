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

# Read event_key from cli if not defined
args <- commandArgs(trailingOnly = TRUE)
if (!exists("event_key")) {
    if (length(args) == 0) {
        event_key <- readline(prompt = "Enter event key: ")
    } else {
        event_key <- args[1]
    }
}

###############

# get event data for input event key
event_all <- get_event_data(event_key, api_key)

# merge event data
event_keys <- c("2023vabla", "2023mdbet", "2023vaale", "2023vapor",
    "2023vagle", "2023mdtim", "2023chcmp")
merged <- get_multi_event_data(event_keys, api_key)

# filtere merged data to contain only teams from one event

# CHANGE THIS VARIABLE TO GET FUTURE EVENT DATA:
filtered_event_key <- event_key
filtered_event_key <- "2023chcmp"
filter_merged <- get_filtered_multi_event_data(filtered_event_key, api_key)

