#
# This file contains (mostly) all the functions that main.R will be calling
#

# Define main output directory
output <- "../output"

#
# produce output spreadsheets for a singular event
#
get_event_data <- function(event_key, api_key) {
    # get teams from event
    event_teams <- get_team_list(event_key, api_key)
    event_teams <- filter_dummy_teams(event_teams)

    # quit if event has less than required number of teams
    # TODO: figure out correct number of teams
    if (length(event_teams) < 18) {
        return(FALSE)
    }

    #
    # Generate event csv files and zip
    #
    out_dir <- glue("{output}/{event_key}")
    if (!dir.exists(glue(out_dir))) {
        dir.create(glue(out_dir))
    }
    file.copy("{output}/README.md", out_dir)

    #
    # Get match data for each team at event
    #
    raw_event_matches <- get_event_matches_raw(event_key, api_key)
    event_teams <- event_teams[which(event_teams %in%
        simplify2array(raw_event_matches$alliances$red$team_keys))]
    event_teams <- event_teams[which(event_teams %in%
        simplify2array(raw_event_matches$alliances$blue$team_keys))]
    rm(list = ls(pattern = "frc"))
    for (team_key in event_teams) {
        out <- get_team_matches(raw_event_matches, team_key)
        assign(glue("{team_key}"), out)
    }


    # Get team OPRs and related stats

    ratings <- get_opr(get_event_matches(raw_event_matches), event_teams)
    write.csv(ratings, glue("{output}/{event_key}/{event_key}_opr.csv"))

    # event-wide team stats
    allteams <- data.frame()
    for (team_key in ls(pattern = "frc")) {
        df <- get(team_key)
        allteams <- get_event_means(allteams, df, ratings, team_key, event_key, output)
    }
    write.csv(allteams, glue("{output}/{event_key}/{event_key}_all.csv"))

    return(allteams)
}


#
# Output spreadsheet from multiple events
#
get_multi_event_data <- function(events_df, api_key) {
    event_keys <- get_filtered_events(events_df)$key
    in_progress <- get_in_progress_events(events_df)
    for (event_key in event_keys) {
        print(event_key)
        if (!dir.exists(glue("{output}/{event_key}"))) {
            if (!(is.data.frame(get_event_data(event_key, api_key)))) {
                event_keys <- event_keys[event_keys != event_key]
            }
            Sys.sleep(0.01)
        } else if (event_key %in% in_progress$key) {
            if (!(is.data.frame(get_event_data(event_key, api_key)))) {
                event_keys <- event_keys[event_keys != event_key]
            }
            Sys.sleep(0.01)
        }
    }
    merged <- merge_events(event_keys, output)
    write.csv(merged, glue("{output}/events_all.csv"), row.names = FALSE)

    return(merged)
}

#
# Output filtered version of multi-event sheet
#
get_filtered_multi_event_data <- function(event_key, api_key) {
    teamlist <- get_team_list(event_key, api_key)
    filtered <- filter_merged(teamlist, event_key, output)
    write.csv(filtered, glue("{output}/{event_key}_filtered.csv"),
        row.names = FALSE
    )
}

