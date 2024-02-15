library(tidyverse)
library(dplyr)
library(glue)
library(jsonlite)
library(magrittr)
library(ggplot2)

source("api/eventmatches.R")
source("api/teammatches.R")
source("api/teamopr.R")
source("model/predict.R")

# generate hypothetical "average" team with average of all stats
# @input opr_df: the opr dataframe
# @input individual_event_flag: flag for whether or not dataframe is
#                         from merged event data or individual event
# default assumes merged event
get_average_stats <- function(opr_df, individual_event_flag = FALSE) {
    if (individual_event_flag == FALSE) {
        opr_df %<>% add_row(
            team = "frc0",
            num_events = 1,
            max_opr = mean(opr_df$max_opr),
            max_auto_opr = mean(opr_df$max_auto_opr),
            max_tele_opr = mean(opr_df$max_tele_opr),
            rp_cr = mean(opr_df$rp_cr),
            auto_climb = mean(opr_df$auto_climb),
            tele_climb = mean(opr_df$tele_climb),
            opr1 = mean(opr_df$opr1),
            opr2 = NULL,
            opr3 = NULL,
            auto_opr1 = mean(opr_df$auto_opr1),
            auto_opr2 = NULL,
            auto_opr3 = NULL,
            tele_opr1 = mean(opr_df$tele_opr1),
            tele_opr2 = NULL,
            tele_opr3 = NULL
        )
        opr_df$opr <- opr_df$max_opr

    } else {
        opr_df %<>% add_row(
            team = "frc0",
            opr = mean(opr_df$opr),
            auto_opr = mean(opr_df$auto_opr),
            teleop_opr = mean(opr_df$teleop_opr),
            auto_opr_ratio = mean(opr_df$auto_opr_ratio),
            # auto_gpc_opr = mean(opr_df$auto_gpc_opr),
            # tele_gpc_opr = mean(opr_df$tele_gpc_opr),
            rp_cr = mean(opr_df$rp_cr)
        )
    }
    return(opr_df)
}

# Estimate schedule difficulty by comparing estimated contribution
# ratings of teams on each side of the match
# - Assumes input team has "average" rating
# @input team_key: team to check schedule of
# @input df: raw event matches dataframe
# @input opr_df: dataframe containing opr ratings
eval_schedule_difficulty <- function(team_key, df, opr_df) {
    teams <- get_team_index(df, team_key)
    teams <- teams[which(teams$comp_level == "qm"), ]
    match_alliances <- tibble(
        alliance = character(),
        r_opr_sum = numeric(),
        b_opr_sum = numeric(),
        opr_diff = numeric(),
        r_rp = numeric(),
        b_rp = numeric(),
        rp_diff = numeric()
    )
    # add "average" team to opr dataframe for later use
    opr_df %<>% get_average_stats()


    for (i in seq_along(teams$match_number)) {
        # replace team occurences with frc0 to signify average
        if (teams$team_alliance[i] == "r") { # team is on red alliance
            if (teams[i, ]$team_index == 1) teams[i, ]$r1 <- "frc0"
            if (teams[i, ]$team_index == 2) teams[i, ]$r2 <- "frc0"
            if (teams[i, ]$team_index == 3) teams[i, ]$r3 <- "frc0"
            red_alliance_teams <- c(teams[i, ]$r1, teams[i, ]$r2, teams[i, ]$r3)
            blue_alliance_teams <- c(
                teams[i, ]$b1, teams[i, ]$b2, teams[i, ]$b3)
            r_sum <- get_alliance_opr(red_alliance_teams, opr_df)
            b_sum <- get_alliance_opr(blue_alliance_teams, opr_df)
            r_rp <- get_alliance_rp_opr(red_alliance_teams, opr_df)
            b_rp <- get_alliance_rp_opr(blue_alliance_teams, opr_df)
            match_alliances %<>%  add_row(
                alliance = teams$team_alliance[i],
                r_opr_sum = r_sum,
                b_opr_sum = b_sum,
                opr_diff = r_sum - b_sum,
                r_rp = r_rp,
                b_rp = b_rp,
                rp_diff = r_rp - b_rp
            )
        } else { # team is on blue alliance
            if (teams[i, ]$team_index == 1) teams[i, ]$b1 <- "frc0"
            if (teams[i, ]$team_index == 2) teams[i, ]$b2 <- "frc0"
            if (teams[i, ]$team_index == 3) teams[i, ]$b3 <- "frc0"
            red_alliance_teams  <- c(
                teams[i, ]$r1, teams[i, ]$r2, teams[i, ]$r3)
            blue_alliance_teams <- c(
                teams[i, ]$b1, teams[i, ]$b2, teams[i, ]$b3)
            r_sum <- get_alliance_opr(red_alliance_teams, opr_df)
            b_sum <- get_alliance_opr(blue_alliance_teams, opr_df)
            r_rp <- get_alliance_rp_opr(red_alliance_teams, opr_df)
            b_rp <- get_alliance_rp_opr(blue_alliance_teams, opr_df)
            match_alliances %<>%  add_row(
                alliance = teams$team_alliance[i],
                r_opr_sum = r_sum,
                b_opr_sum = b_sum,
                opr_diff = b_sum - r_sum,
                r_rp = r_rp,
                b_rp = b_rp,
                rp_diff = b_rp - r_rp
            )
        }
    }

    # TODO: add additional metrics, i.e. ranking scores, pull from other
    # opr spreadsheet (format opr spreadsheet function)

    opr_diff <- sum(match_alliances$opr_diff) / length(teams$match_number)
    rp_diff_rating <- sum(match_alliances$rp_diff) / length(teams$match_number)
    return(tibble(
            team = team_key,
            opr_difficulty_rating = opr_diff,
            rp_difficulty_rating = rp_diff_rating
        )
    )
}

