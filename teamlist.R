# get list of all teams at an event
# @input event_key: key for frc event found from blue alliance
# @input api_key: blue alliance api key found on account dashboard
getTeamList <- function(event_key, api_key) {
    link <- glue("'https://www.thebluealliance.com/api/v3/event/{event_key}/teams'")
    args <- glue("curl -X 'GET' {link} -H 'accept: application/json' -H 'X-TBA-Auth-Key: {api_key}'")
    return((system(args, intern=T) %>% fromJSON())$key)
}

