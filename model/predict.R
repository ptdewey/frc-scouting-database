library(tidyverse)
library(dplyr)
library(glue)
library(jsonlite)
library(magrittr)
library(ggplot2)

source("api/eventmatches.R")
source("api/teammatches.R")
source("api/teamopr.R")

# For testing purposes:
# Subset data into training and testing subsets
# assumes full data for event exists
# @input event_key: tba event key
# @input api_key: tba api key
subset_train_test <- function(event_key, api_key) {
    raw_event_matches <- getEventMatchesRaw(event_key, api_key)
    event_matches <- getEventMatches(raw_event_matches)
    trainobs <- .7 * length(event_matches$match_number)
    event_matches_train <- event_matches[1:trainobs, ]
    event_matches_test <- event_matches[-(1:trainobs), ]
    return(list(event_matches_train, event_matches_test))
}

# subset played vs unplayed (hypothetical) matches
# use with for incomplete event - predict day 2 match outcomes
subset_played_unplayed <- function(event_key, api_key) {
    raw_event_matches <- getEventMatchesRaw(event_key, api_key)
    event_matches <- getEventMatches(raw_event_matches)
    event_matches_played <- event_matches[
    which(event_matches$r_score != -1), ]
    event_matches_unplayed <- event_matches[
    which(event_matches$r_score == -1), ]
    return(list(event_matches_played, event_matches_unplayed))
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
    opr_df %<>% add_row(
        team = "frc0",
        opr = mean(opr_df$opr),
        auto_opr = mean(opr_df$auto_opr),
        teleop_opr = mean(opr_df$teleop_opr),
        auto_opr_ratio = mean(opr_df$auto_opr_ratio),
        auto_gpc_opr = mean(opr_df$auto_gpc_opr),
        tele_gpc_opr = mean(opr_df$tele_gpc_opr),
        rp_opr = mean(opr_df$rp_opr)
    )

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

# Fetch expected contribution for each team in a match
# (pull prior info?)
# @input alliance_teams: list of teams on alliance
# @input opr_df: opr dataframe
get_alliance_opr <- function(alliance_teams, opr_df) {
    opr_sum <- 0
    for (team_key in alliance_teams) {
        opr_sum <- opr_sum + opr_df[which(opr_df$team == team_key), ]$opr
    }
    return(opr_sum)
}


# Fetch expected ranking point contribution for each team in a match
# @input alliance_teams: list of teams on alliance
# @input opr_df: opr dataframe
get_alliance_rp_opr <- function(alliance_teams, opr_df) {
    opr_sum <- 0
    for (team_key in alliance_teams) {
        opr_sum <- opr_sum + opr_df[which(opr_df$team == team_key), ]$rp_opr
    }
    return(opr_sum)
}


# Generate simulated match for two arbitrary alliances
gen_match <- function() {
    # TODO:
}

# local helper function to determine match outcome
get_winner <- function(r_v, b_v) {
    out <- r_v - b_v
    out[which(out > 0)] <- "red"
    out[which(out < 0)] <- "blue"
    out[which(out == 0)] <- "tie"
    return(out)
}

# Output predicted match outcomes
# @input subset_event_matches: list of matches subset into train/test etc.
# @input opr_df: dataframe containing opr information to pull from
get_predictions <- function(subset_event_matches, opr_df) {
    # event_matches_test <- as.data.frame(subset_event_matches[2])
    event_matches_test <- subset_event_matches
    red_test <- select(event_matches_test, c(r1, r2, r3))
    blue_test <- select(event_matches_test, c(b1, b2, b3))

    # get team estimated contributions
    # TODO: deal with potential case of no matches (i.e. set prior opr rating)
    blue_opr <- c()
    red_opr <- c()
    for (i in seq_along(event_matches_test$match_number)) {
        opr_sum <- 0
        for (team in red_test[i, ]) {
            opr_sum <- opr_sum + opr_df[which(opr_df$team == team), ]$opr
        }
        red_opr <- append(red_opr, opr_sum)
        opr_sum <- 0
        for (team in blue_test[i, ]) {
            opr_sum <- opr_sum + opr_df[which(opr_df$team == team), ]$opr
        }
        blue_opr <- append(blue_opr, opr_sum)
    }

    pred_test <- cbind(red_test, blue_test) %>%
        mutate(r_pred_score = red_opr[seq_along(event_matches_test[, 1])]) %>%
        mutate(b_pred_score = blue_opr[seq_along(event_matches_test[, 1])]) %>%
        mutate(pred_winner = get_winner(r_pred_score, b_pred_score)) %>%
        mutate(pred_winning_margin = abs(r_pred_score - b_pred_score))


    return(pred_test)
}

# generate predictions for elimination matches
gen_pred_elims <- function(raw_event_matches, opr_df) {
    matches <- getEventMatches(matches)
    matches <- matches[which(matches$comp_level != "qm"), ]
    matches <- matches[which(matches$r1 != "frc0")]
    red_test <- select(matches, c(r1, r2, r3))
    blue_test <- select(matches, c(b1, b2, b3))

    # get team estimated contributions
    blue_opr <- c()
    red_opr <- c()
    for (i in seq_along(matches$match_number)) {
        opr_sum <- 0
        for (team in red_test[i, ]) {
            opr_sum <- opr_sum + opr_df[which(opr_df$team == team), ]$opr
        }
        red_opr <- append(red_opr, opr_sum)
        opr_sum <- 0
        for (team in blue_test[i, ]) {
            opr_sum <- opr_sum + opr_df[which(opr_df$team == team), ]$opr
        }
        blue_opr <- append(blue_opr, opr_sum)
    }

    elim_preds <- cbind(red_test, blue_test) %>%
        mutate(r_pred_score = red_opr[seq_along(matches[, 1])]) %>%
        mutate(b_pred_score = blue_opr[seq_along(matches[, 1])]) %>%
        mutate(pred_winner = get_winner(r_pred_score, b_pred_score)) %>%
        mutate(pred_winning_margin = abs(r_pred_score - b_pred_score))

    return(elim_preds)
}

# evaluate accuracy of predictions
# @input subset_event_matches: dataframe containing predicted matches
# @input preds: dataframe of predictions
eval_predictions <- function(subset_event_matches, preds) {
    subset_event_matches[1]
    matches_played <- as.data.frame(subset_event_matches[1])
    match_nums <- preds[, 1]
    print(matches_played$match_number)
    print(match_nums)
    matches_played
    # TODO: make work

    # matches_played <- matches_played %>% filter(match_nums %in% matches_played)
    which(match_nums %in% matches_played)

    print(matches_played$r_score)
    red <- select(preds, c(r1, r2, r3))
    blue <- select(preds, c(b1, b2, b3))
    eval <- cbind(red, blue) %>% 
        mutate(r_pred_score = preds$r_pred_score) %>%
        mutate(b_pred_score = preds$b_pred_score) %>%
        mutate(pred_winner = get_winner(r_pred_score, b_pred_score)) %>%
        mutate(pred_winning_margin = abs(r_pred_score - b_pred_score)) %>%
        mutate(actual_r_score = matches_played$r_score) %>%
        mutate(actual_b_score = matches_played$b_score) %>%
        mutate(actual_winner = get_winner(actual_r_score, actual_b_score)) %>%
        mutate(actual_winning_margin = abs(actual_r_score - actual_b_score)) %>%
        mutate(correct = (pred_winner == actual_winner)) %>%
        mutate(pred_margin_diff = pred_winning_margin - actual_winning_margin)
    return(eval)
}

