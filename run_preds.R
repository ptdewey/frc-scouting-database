library(tidyverse)
library(dplyr)
library(tibble)

source("api/eventmatches.R")
source("api/teamopr.R")
source("model/predict.R")
source("api/teamlist.R")

# Read api key from .env
if (!exists("api_key")) {
    readRenviron(".env")
    api_key <- Sys.getenv("API_KEY")
}


# event_key <- "2023arc"
# champs division keys
filtered_keys <- c("2023arc", "2023cur", "2023dal",
    "2023gal", "2023hop", "2023joh", "2023mil"
)
for (event_key in filtered_keys) {
    raw_matches <- getEventMatchesRaw(event_key, api_key)
    # matches <- subset_played_unplayed(event_key, api_key)
    # matches_df <- as.data.frame(matches[1])
    matches_df <- get_pre_event_matches(raw_matches)

    opr_df <- read_csv(glue("output/{event_key}_filtered.csv"))
    opr_df$opr <- opr_df$max_opr

    # event_teams <- getTeamList(event_key, api_key)

    # schedules <- tibble(
    #     team = character(),
    #     opr_difficulty_rating = numeric(),
    #     rp_difficulty_rating = numeric(),
    # )
    # for (team in event_teams) {
                # schedules %<>% add_row(
    #               eval_schedule_difficulty(team, raw_matches, opr_df))
    # }


    out <- get_predictions(matches_df, opr_df)[1]
# write.csv(out, glue("output/{event_key}/{event_key}_predictions.csv"))
    write.csv(out, glue("output/{event_key}_predictions.csv"))
}

# preds <- read_csv("output/2023chcmp_predictions.csv")
# write.csv(eval_predictions(matches[1], preds),
#     glue("output/{event_key}_evaluated_predictions.csv"))

