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
readRenviron(".env")
api_key <- Sys.getenv("API_KEY")

# Read event_key from cli
args = commandArgs(trailingOnly=TRUE)
if (length(args) == 0) {
    event_key <- readline(prompt = "Enter event key: ")
} else {
    event_key <- args[1]
}

# get teams from event
event_teams <- getTeamList(event_key, api_key)

#
# Get match data for each team at event
#
# this is part is a bit slow
rm(list=ls(pattern="frc"))
for (team_key in event_teams) {
    out <- getTeamMatches(team_key, event_key, api_key)
    assign(glue("{team_key}"), out)
}

#
# Generate event csv files and zip
#
if (!dir.exists(glue("output/{event_key}"))) {
    dir.create(glue("output/{event_key}"))
}

# Get team OPRs and related stats
ratings <- getOpr(getEventMatches(event_key, api_key), event_teams)
write.csv(ratings, glue("output/{event_key}/{event_key}_opr.csv"))

# event-wide team stats
allteams <- data.frame()
for (team_key in ls(pattern="frc")) {
    df <- get(team_key)
    allteams <- getEventMeans(allteams, df, ratings, team_key, event_key)
}
write.csv(allteams, glue('output/{event_key}/{event_key}_all.csv'))

