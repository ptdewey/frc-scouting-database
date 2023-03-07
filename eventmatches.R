# create dataframe containing all matches from event
# @input event_key: TBA event key
# @input api_key: TBA api key
getEventMatches <- function(event_key, api_key) {
    link <- glue("'https://www.thebluealliance.com/api/v3/event/{event_key}/matches'")
    args <- glue("curl -X 'GET' {link} -H 'accept: application/json' -H 'X-TBA-Auth-Key: {api_key}'")
    oldw <- getOption("warn")
    options(warn = -1) 
    df <- system(args, intern=T) %>% fromJSON() %>%
        group_by(comp_level) %>%
        arrange(match_number, .by_group=TRUE) %>%
        as.data.frame()
    options(warn = oldw)

    # create output dataframe
    out <- data.frame(df$comp_level, df$match_number, df$alliances$red$score, 
        df$score_breakdown$red$autoPoints, df$score_breakdown$red$teleopPoints, 
        df$alliances$blue$score, df$score_breakdown$blue$autoPoints,
        df$score_breakdown$blue$teleopPoints,
        t(simplify2array(df$alliances$red$team_keys)),
        t(simplify2array(df$alliances$blue$team_keys)))
    colnames(out) <- c('comp_level', 'match_number', 'r_score', 'r_auto_score',
        'r_teleop_score', 'b_score', 'b_auto_score', 'b_teleop_score', 
        'r1', 'r2', 'r3', 'b1', 'b2', 'b3')

    return(out)
}

