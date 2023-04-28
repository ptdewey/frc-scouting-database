library(dplyr)
library(magrittr)
library(glue)
library(jsonlite)

# EVENT TYPE CODES:
# 100: pre-season event
# 99: post-season event
# 0: regional events
# 1: district events
# 2: district championship events (non-division)
# 4: world championship event
# 5: district championship events (division)

# gets all events in a given season
# @input year: year of events
# @input api_key: blue alliance api key
get_event_list <- function(year, api_key) {
    # TODO: try to use non-simple output
    link <- glue("'https://www.thebluealliance.com/api/v3/events/{year}/simple'")
    cmd_call <- glue("curl -X 'GET' {link} -H 'accept: application/json' -H 'X-TBA-Auth-Key: {api_key}'")
    return((system(cmd_call, intern = TRUE) %>% fromJSON()))
}

# get only played/seasonal events
# @input events_df: dataframe from get_event_list
get_filtered_events <- function(events_df) {
    events_df %<>%
        filter(start_date < Sys.Date()) %>%
        filter(event_type != 100) %>% # remove pre-season events
        filter(event_type != 99) # remove post-season events

    # TODO: try to use non-simple output parameters to better filter this
    type_2 <- events_df$key[which(events_df$event_type == 2)]
    type_5 <- events_df$key[which(events_df$event_type == 5)]
    for (event in type_2) {
        if (TRUE %in% grepl(event, type_5)) {
            events_df <- events_df[which(events_df$key != event), ]
        }
        # print(which(grepl(event, type_5) == FALSE))
    }
    return(events_df)
}

