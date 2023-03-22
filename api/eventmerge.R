library(tidyverse)
library(readr)
library(purrr)
library(dplyr)
library(magrittr)
library(tibble)
library(glue)

# pull_event_data <- function(event_keys) {
#     #
#     events <- list()
#     return(events)
# }

# merge spreadsheets from multiple events
# @input event_keys: list of event keys to merge
merge_events <- function(event_keys) {
    df <- read_csv(glue("output/{event_keys}/{event_keys}_all.csv"))

    # get list of unique teams and number of occurences
    teams <- df %>%
        count(team) %>%
        arrange(desc(n))

    # potential additional output metrics:
    # max/mean/weighted mean opr
    # initial opr? (prior/baseline)
    # district champs opr (opr3?)
    # champs opr (opr4?)
    # count/percent climb and balanced

    # add to other spreadsheets for this:
    # ranking score/points (mean/total/max/recent)
    # num matches and/or competitions
    # opr error (loo method)
    # season wins (total wins?)

    # define output dataframe
    out <- tibble(
        team = character(),
        num_events = integer(),
        max_opr = numeric(),
        max_auto_opr = numeric(),
        max_tele_opr = numeric(),
        auto_climb_count = integer(), # change to ratio later
        tele_climb_count = integer(),
        opr1 = numeric(),
        opr2 = numeric(),
        auto_opr1 = numeric(),
        auto_opr2 = numeric(),
        tele_opr1 = numeric(),
        tele_opr2 = numeric()
    )

    # helper function for map
    append_team <- function(team, out, df) {
        team_rows <- df[which(df$team == team), ]
        out %<>% add_row(
            team = team,
            num_events = teams[which(teams$team == team), ]$n,
            max_opr = max(team_rows$opr),
            max_auto_opr = max(team_rows$auto_opr),
            max_tele_opr = max(team_rows$teleop_opr),
            auto_climb_count = sum(team_rows$count_auto_dock),
            tele_climb_count = sum(team_rows$count_tele_dock),
            opr1 = team_rows[1, ]$opr,
            opr2 = team_rows[2, ]$opr,
            auto_opr1 = team_rows[1, ]$auto_opr,
            auto_opr2 = team_rows[2, ]$auto_opr,
            tele_opr1 = team_rows[1, ]$teleop_opr,
            tele_opr2 = team_rows[2, ]$teleop_opr
        )
    }
    out <- map_dfr(teams$team, append_team, out = out, df = df) %>%
        arrange(desc(max_opr))

    # TODO: figure out best metric to group output by
    # likely opr, but currently is num_events)
    return(out)
}

# Create merged output dataframe containing only teams from list
# @input event_teams: list of teams
# @input event_key: event key or name for ouput
filter_merged <- function(event_teams, event_key) {
    df <- read_csv("output/events_all.csv")
    out <- df[which(df$team %in% event_teams), ]
    return(out)
}

