# get match data for input team
# @input team_key: team key i.e 'frc254'
# @input event_key: event key found on blue alliance
# @input api_key: blue alliance api key found on account dashboard
getTeamMatches <- function(team_key, event_key, api_key) {
    link <- glue("https://www.thebluealliance.com/api/v3/team/{team_key}/event/{event_key}/matches")
    args <- glue("curl -X 'GET' {link} -H 'accept: application/json' -H 'X-TBA-Auth-Key: {api_key}'")
    oldw <- getOption("warn")
    options(warn = -1) 
    out <- system(args, intern=T) %>% fromJSON() %>%
        arrange(match_number) %>% 
        getTeamData(team_key) %>%
        as.data.frame()
    options(warn = oldw)
    return(out)
}

