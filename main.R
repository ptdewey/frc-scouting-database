library(tidyverse)
library(dplyr)
library(glue)
library(stringr)
library(jsonlite)

source('teamlist.R')
source('teamscore.R')
source('eventmatches.R')
source('teammatches.R')
source('teamopr.R')
source('eventmean.R')

# Read api key from .env
if (!exists('api_key')) {
    readRenviron(".env")
    api_key <- Sys.getenv("API_KEY")
}

# Read event_key from cli if not defined
args = commandArgs(trailingOnly=TRUE)
if (!exists('event_key')) {
    if (length(args) == 0) {
        event_key <- readline(prompt = "Enter event key: ")
    } else {
        event_key <- args[1]
    }
}

# get teams from event
# TODO: maybe change to pull from matches? (might deal with teams with no matches)
event_teams <- getTeamList(event_key, api_key)

#
# Get match data for each team at event
#
raw_event_matches <- getEventMatchesRaw(event_key, api_key)
rm(list=ls(pattern="frc"))
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
file.copy('output/data_dictionary.md', out_dir)

# Get team OPRs and related stats

ratings <- getOpr(getEventMatches(raw_event_matches), event_teams)
write.csv(ratings, glue("output/{event_key}/{event_key}_opr.csv"))

# event-wide team stats
allteams <- data.frame()
for (team_key in ls(pattern="frc")) {
    df <- get(team_key)
    allteams <- getEventMeans(allteams, df, ratings, team_key, event_key)
}
write.csv(allteams, glue('output/{event_key}/{event_key}_all.csv'))

