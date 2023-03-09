# create dataframe containing all matches from event
# @input df: raw event matches dataframe from getEventMatchesRaw()  
# @input team_key: team key (i.e. 'frc254')
getTeamMatches <- function(df, team_key) {
    # get alliances
    keysr <- as.data.frame(t(simplify2array(df$alliances$red$team_keys)))
    keysb <- as.data.frame(t(simplify2array(df$alliances$blue$team_keys)))

    # get match numbers where team appears
    match_numbers <- sort(c(which(team_key == keysb[,1]), 
        which(team_key == keysb[,2]), which(team_key == keysb[,3]),
        which(team_key == keysr[,1]), which(team_key == keysr[,2]),
        which(team_key == keysr[,3])))
    
    out <- df[match_numbers,] %>%
        getTeamData(team_key) %>%
        as.data.frame()

    return(out)
}

