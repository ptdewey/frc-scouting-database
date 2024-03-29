library(tidyverse)
library(readr)
library(purrr)
library(dplyr)
library(magrittr)
library(tibble)
library(glue)

# merge spreadsheets from multiple events
# @input event_keys: list of event keys to merge
merge_events <- function(event_keys, output_dir) {
    df <- read_csv(glue("{output_dir}/{event_keys}/{event_keys}_all.csv"))

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
        rp_cr = numeric(),
        opr1 = numeric(),
        opr2 = numeric(),
        opr3 = numeric(),
        auto_opr1 = numeric(),
        auto_opr2 = numeric(),
        auto_opr3 = numeric(),
        tele_opr1 = numeric(),
        tele_opr2 = numeric(),
        tele_opr3 = numeric()
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
            rp_cr = max(team_rows$rpcr),
            opr1 = team_rows[1, ]$opr,
            opr2 = team_rows[2, ]$opr,
            opr3 = team_rows[3, ]$opr,
            auto_opr1 = team_rows[1, ]$auto_opr,
            auto_opr2 = team_rows[2, ]$auto_opr,
            auto_opr3 = team_rows[3, ]$auto_opr,
            tele_opr1 = team_rows[1, ]$teleop_opr,
            tele_opr2 = team_rows[2, ]$teleop_opr,
            tele_opr3 = team_rows[3, ]$teleop_opr
        )
    }
    out <- map_dfr(teams$team, append_team, out = out, df = df) %>%
        arrange(desc(max_opr))

    return(out)
}

# Create merged output dataframe containing only teams from list
# @input event_teams: list of teams
# @input event_key: event key or name for ouput
filter_merged <- function(event_teams, event_key, output_dir) {
    df <- read_csv(glue("{output_dir}/events_all.csv"))
    out <- df[which(df$team %in% event_teams), ]
    return(out)
}

