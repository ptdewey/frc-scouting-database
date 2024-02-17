library(tidyverse)
library(dplyr)
library(tibble)

source("../stats-app/api/eventmatches.R")
source("../stats-app/api/teamopr.R")
source("../stats-app/api/teamlist.R")
source("model/predict.R")
source("model/evalschedule.R")

# Read api key from .env
if (!exists("api_key")) {
    readRenviron(".env")
    api_key <- Sys.getenv("API_KEY")
}

# TODO: change this for newer events
event_keys <- c("2024vagle")


# define path to output directory
output_dir <- "../output"

for (event_key in event_keys) {
    print(glue("Getting data for {event_key}..."))
    raw_matches <- get_event_matches_raw(event_key, api_key)

    ## dfferent match subsetting methods
    # TODO: figure out if anything is needed beyond pre_event info?

    # matches <- subset_played_unplayed(event_key, api_key)
    # matches_df <- as.data.frame(matches[1])
    matches_df <- get_pre_event_matches(raw_matches)
    # matches_df <- get_event_matches(raw_matches)

    opr_df <- read_csv(glue("{output_dir}/{event_key}_filtered.csv"))
    opr_df$opr <- opr_df$max_opr

    # Create predictions directory for cleaner output
    preds_dir <- glue("{output_dir}/predictions")
    if (!dir.exists(preds_dir)) {
        dir.create(preds_dir)
    }
    out <- get_predictions(matches_df, opr_df)[1]
    now <- format(Sys.time(), "%Y_%m_%d_%H:%M:%S")
    event_dir <- glue("{preds_dir}/{now}_{event_key}")
    dir.create(event_dir)
    write.csv(out, glue("{event_dir}/{event_key}_predictions.csv"))

    # schedule stuff
    event_teams <- get_team_list(event_key, api_key)
    schedules <- tibble(
        team = character(),
        opr_difficulty_rating = numeric(),
        rp_difficulty_rating = numeric(),
    )
    for (team in event_teams) {
        schedules %<>% add_row(
            eval_schedule_difficulty(team, raw_matches, opr_df))
    }
    schedules %<>% arrange(opr_difficulty_rating)
    write.csv(schedules, glue("{event_dir}/{event_key}_schedules.csv"))

    # Subset matches to allow evaluating predictions
    matches <- subset_played_unplayed(event_key, api_key)

    # TODO: add flag as input param to allow evaluation of predictions

    # evaluate predictions
    print(glue("Evaluating predictions for {event_key}..."))
    # check all matching predictions in predictions directory
    dirs_list <- list.dirs(glue("{output_dir}/predictions"), recursive = FALSE)
    dirs_list <- dirs_list[which(grepl(event_key, dirs_list))]
    for (dir in dirs_list) {
        preds <- read_csv(glue("{dir}/{event_key}_predictions.csv"))
        write.csv(eval_predictions(matches[1], preds),
            glue("{dir}/{event_key}_evaluated_predictions.csv"))
    }

    print("...Done!")
}

