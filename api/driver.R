#
# This file contains (mostly) all the functions that main.R will be calling
#

#
# produce output spreadsheets for a singular event
#
get_event_data <- function(event_key, api_key) {
# get teams from event
    event_teams <- getTeamList(event_key, api_key)

#
# Get match data for each team at event
#
    raw_event_matches <- getEventMatchesRaw(event_key, api_key)
    rm(list = ls(pattern = "frc"))
    for (team_key in event_teams) {
        out <- getTeamMatches(raw_event_matches, team_key)
        assign(glue("{team_key}"), out)
    }

#
# Generate event csv files and zip
#
    out_dir <- glue("output/{event_key}")
    if (!dir.exists(glue(out_dir))) {
        dir.create(glue(out_dir))
    }
    file.copy("output/README.md", out_dir)

# Get team OPRs and related stats

    ratings <- getOpr(getEventMatches(raw_event_matches), event_teams)
    write.csv(ratings, glue("output/{event_key}/{event_key}_opr.csv"))

# event-wide team stats
    allteams <- data.frame()
    for (team_key in ls(pattern = "frc")) {
        df <- get(team_key)
        allteams <- getEventMeans(allteams, df, ratings, team_key, event_key)
    }
    write.csv(allteams, glue("output/{event_key}/{event_key}_all.csv"))

    return(allteams)
}


#
# Output spreadsheet from multiple events
#
get_multi_event_data <- function(event_keys, api_key) {
    for (event_key in event_keys) {
        if (!dir.exists(glue("output/{event_key}"))) {
            get_event_data(event_key, api_key)
        }
    }
    merged <- merge_events(event_keys)
    write.csv(merged, glue("output/events_all.csv"))

    return(merged)
}

#
# Output filtered version of multi-event sheet
#
get_filtered_multi_event_data <- function(event_key, api_key) {
    teamlist <- getTeamList(event_key, api_key)
    filtered <- filter_merged(teamlist, event_key)
    write.csv(filtered, glue("output/{event_key}_filtered.csv"))
}

