library(tidyverse)
library(dplyr)
library(stringr)
library(jsonlite)

source('teamscore.R')

# get teams from event
# teams <- fromJSON('data/vabla_teams.json')
# teamkeys <- teams$key
# write(teamkeys, 'data/teams.txt')

#
# read all team match files
#
setwd('./input')
files <- list.files(pattern = "m_frc")
for (file in files) {
    # Get team name from filenames
    tkey <- simplify2array(str_split(file, '.json'))[1]
    tkey <- simplify2array(str_split(tkey, 'm_'))[2]
    
    # get output dataframe
    out <- fromJSON(file) %>% 
        arrange(match_number) %>% 
        getTeamData(tkey) 

    setwd('../output')
    # write dataframe to spreadsheet
    write.csv(out, paste(tkey,'.csv', sep=''))
    setwd('../input')
}


# 
# Make master csv file
#
allteams <- data.frame()
setwd('../output')
files <- list.files(pattern = "frc")
for (file in files) {
    tkey <- simplify2array(str_split(file, '.csv'))[1]
    df <- read.csv(file)
    # clean out unplayed matches
    df <- df[which(df$scores != -1),]
    auto_dock <- length(which(df$auto_dock == 'Docked'))
    auto_balance <- length(which(df$auto_balance == 'Level' & df$auto_dock == 'Docked'))
    tele_dock <- length(which(df$tele_dock == 'Docked'))
    tele_balance <- length(which(df$tele_balance == 'Level' & df$tele_dock == 'Docked'))

    # TODO COUNTS OF DOCKS AND BALANCES
    allteams <- rbind(allteams, c(tkey, 
        mean(df$scores), mean(df$auto_gpp), mean(df$auto_p), auto_dock, auto_balance, 
        mean(df$tele_gpp), mean(df$tele_p), tele_dock, tele_balance))
}
cols <- c('team', 'avg_score', 'avg_auto_game_piece_points', 'avg_auto_points', 
    'count_auto_dock', 'count_auto_level', 'avg_tele_game_piece_points', 
    'avg_tele_points', 'count_tele_dock', 'count_tele_balance')
colnames(allteams) <- cols

write.csv(allteams, 'vabla_allteams.csv')
