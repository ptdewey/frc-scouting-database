library(dplyr)
library(jsonlite)
library(glue)

# get all matches from event, raw output form, json schema
# @input event_key: tba event key
# @input api_key: tba api key
get_event_matches_raw <- function(event_key, api_key) {
    link <- glue("'https://www.thebluealliance.com/api/v3/event/{event_key}/matches'")
    cmd <- glue("curl -X 'GET' {link} -H 'accept: application/json' -H 'X-TBA-Auth-Key: {api_key}'")
    oldw <- getOption("warn")
    options(warn = -1)
    df <- system(cmd, intern = TRUE) %>%
        fromJSON() %>%
        group_by(comp_level) %>%
        arrange(match_number, .by_group = TRUE) %>%
        as.data.frame()
    options(warn = oldw)
    return(df)
}

# create dataframe containing all matches from event
# @input df: raw event matches dataframe
get_event_matches <- function(df) {
    # create output dataframe
    out <- data.frame(df$comp_level, df$match_number, df$alliances$red$score,
        df$score_breakdown$red$autoPoints, df$score_breakdown$red$teleopPoints,
        df$alliances$blue$score, df$score_breakdown$blue$autoPoints,
        df$score_breakdown$blue$teleopPoints,
        t(simplify2array(df$alliances$red$team_keys)),
        t(simplify2array(df$alliances$blue$team_keys)),
        df$score_breakdown$red$rp,
        df$score_breakdown$blue$rp
    )
    colnames(out) <- c("comp_level", "match_number", "r_score", "r_auto_score",
        "r_teleop_score", "b_score", "b_auto_score", "b_teleop_score",
        "r1", "r2", "r3", "b1", "b2", "b3", "r_rp", "b_rp")

    return(out)
}

# gets information on event's matches before event start
# used because score_breakdown stats are not accessible before
# 1st match is played
# @input df: raw matches dataframe
get_pre_event_matches <- function(df) {
    out <- data.frame(
        df$comp_level, df$match_number, df$alliances$red$score,
        df$alliances$blue$score,
        t(simplify2array(df$alliances$red$team_keys)),
        t(simplify2array(df$alliances$blue$team_keys))
    )
    colnames(out) <- c("comp_level", "match_number", "r_score", "b_score",
        "r1", "r2", "r3", "b1", "b2", "b3")
    return(out)
}

