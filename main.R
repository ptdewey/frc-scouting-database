library(tidyverse)
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
    out <- fromJSON(file) %>% getTeamData(tkey) 
    setwd('../output')
    # write dataframe to spreadsheet
    write.csv(out, paste(tkey,'.csv', sep=''))
    setwd('../input')
    
    # TODO: team means 
}


# 
# Make master csv file
#
# allteams <- data.frame()
# setwd('../output')
# files <- list.files(pattern = ".csv")
# for (file in files) {
#     team <- c()
#     tkey <- simplify2array(str_split(file, '.csv'))[1]
#     df <- read_csv(file)
#     avg_score <- df$scores    
#
#     allteams <- cbind(allteams, team)
# }


