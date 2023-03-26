library(tidyverse)
library(dplyr)
library(glue)
library(jsonlite)
library(ggplot2)

source("api/eventmatches.R")
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
get_alliance_info <- function() {
    # TODO:
}

gen_match <- function() {
    # TODO:
}

# Output predicted match outcomes
# @input subset_event_matches: list of matches subset into train/test etc.
# @input opr_df: dataframe containing opr information to pull from
get_predictions <- function(subset_event_matches, opr_df) {
    # local helper function to determine match outcome
    get_winner <- function(r_v, b_v) {
        out <- r_v - b_v
        out[which(out > 0)] <- "red"
        out[which(out < 0)] <- "blue"
        out[which(out == 0)] <- "tie"
        return(out)
    }
    event_matches_train <- as.data.frame(subset_event_matches[1])
    event_matches_test <- as.data.frame(subset_event_matches[2])
    red_train <- select(event_matches_train, c(r1, r2, r3))
    blue_train <- select(event_matches_train, c(b1, b2, b3))
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

