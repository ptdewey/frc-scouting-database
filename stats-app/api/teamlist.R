# get list of all teams at an event
# @input event_key: key for frc event found from blue alliance
# @input api_key: blue alliance api key found on account dashboard
get_team_list <- function(event_key, api_key) {
    link <- glue("'https://www.thebluealliance.com/api/v3/event/{event_key}/teams'")
    cmd <- glue("curl -X 'GET' {link} -H 'accept: application/json' -H 'X-TBA-Auth-Key: {api_key}'")
    return((system(cmd, intern = TRUE) %>% fromJSON())$key)
}

# remove dummy teams numbers when necessary
# idk why these are used, but they break the opr functions when they show up
filter_dummy_teams <- function(teams_list) {
    dummy_keys <- c("frc9980", "frc9981", "frc9982", "frc9983", "frc9984",
        "frc9985", "frc9986", "frc9987", "frc9988", "frc9989", "frc9990",
        "frc9991", "frc9992", "frc9993", "frc9994", "frc9995", "frc9996",
        "frc9997", "frc9998", "frc9999"
    )
    teams_list <- teams_list[which(!(teams_list %in% dummy_keys))]
    return(teams_list)
}

