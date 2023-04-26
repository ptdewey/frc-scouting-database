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
        opr_sum <- opr_sum + opr_df[which(opr_df$team == team_key), ]$rp_cr
    }
    return(opr_sum)
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
get_predictions <- function(event_matches_test, opr_df) {
    red_test <- select(event_matches_test, c(r1, r2, r3))
    blue_test <- select(event_matches_test, c(b1, b2, b3))

    # get team estimated contributions
    # TODO: deal with potential case of no matches (i.e. set prior opr rating)
    red_opr <- c()
    red_rp <- c()
    blue_opr <- c()
    blue_rp <- c()
    for (i in seq_along(event_matches_test$match_number)) {
        opr_sum <- 0
        rp_sum <- 0
        for (team in red_test[i, ]) {
            opr_sum <- opr_sum + opr_df[which(opr_df$team == team), ]$opr
            rp_sum <- rp_sum + opr_df[which(opr_df$team == team), ]$rp_cr
        }
        red_opr <- append(red_opr, opr_sum)
        red_rp <- append(red_rp, rp_sum)
        opr_sum <- 0
        rp_sum <- 0
        for (team in blue_test[i, ]) {
            opr_sum <- opr_sum + opr_df[which(opr_df$team == team), ]$opr
            rp_sum <- rp_sum + opr_df[which(opr_df$team == team), ]$rp_cr
        }
        blue_opr <- append(blue_opr, opr_sum)
        blue_rp <- append(blue_rp, rp_sum)
    }

    pred_test <- cbind(red_test, blue_test) %>%
        mutate(r_pred_score = red_opr[seq_along(event_matches_test[, 1])]) %>%
        mutate(b_pred_score = blue_opr[seq_along(event_matches_test[, 1])]) %>%
        mutate(pred_winner = get_winner(r_pred_score, b_pred_score)) %>%
        mutate(pred_winning_margin = abs(r_pred_score - b_pred_score)) %>%
        mutate(r_pred_rp = red_rp[seq_along(event_matches_test[, 1])]) %>%
        mutate(b_pred_rp = blue_rp[seq_along(event_matches_test[, 1])])

    # TODO: predict ranks
    pred_ranks <- 0

    return(list(pred_test, pred_ranks))
}

# generate predictions for elimination matches
gen_pred_elims <- function(raw_event_matches, opr_df) {
    # TODO: requires simulator
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
eval_predictions <- function(event_matches, preds) {
    matches_played <- as.data.frame(event_matches)
    preds %<>% rename(match_number = names(.)[1])
    if (length(event_matches$matches_played) > length(preds$match_number)) {
        matches_played <- matches_played[
            which(preds$match_number == matches_played$match_number), ]
    } else {
        preds <- preds[
            which(preds$match_number == matches_played$match_number), ]
    }


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
        mutate(r_score_diff = r_pred_score - actual_r_score) %>%
        mutate(b_score_diff = b_pred_score - actual_b_score) %>%
        mutate(pred_margin_diff = pred_winning_margin - actual_winning_margin)
    return(eval)
}

