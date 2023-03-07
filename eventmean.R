getEventMeans <- function(allteams, df, team_key, event_key) {
    # create team csv file
    write.csv(df, glue("output/{event_key}/{event_key}_{team_key}.csv"))
    # clean out unplayed matches
    df <- df[which(df$scores != -1),]
    auto_dock <- length(which(df$auto_dock == 'Docked'))
    auto_balance <- length(which(df$auto_balance == 'Level' & df$auto_dock == 'Docked'))
    tele_dock <- length(which(df$tele_dock == 'Docked'))
    tele_balance <- length(which(df$tele_balance == 'Level' & df$tele_dock == 'Docked'))

    allteams <- rbind(allteams, c(team_key, 
        mean(as.numeric(df$scores)), mean(as.numeric(df$auto_gpp)), 
        mean(as.numeric(df$auto_p)), auto_dock, auto_balance, 
        mean(as.numeric(df$tele_gpp)), mean(as.numeric(df$tele_p)), 
        tele_dock, tele_balance))

    cols <- c('team', 'avg_score', 'avg_auto_game_piece_points', 'avg_auto_points', 
        'count_auto_dock', 'count_auto_level', 'avg_tele_game_piece_points', 
        'avg_tele_points', 'count_tele_dock', 'count_tele_balance')
    colnames(allteams) <- cols

    return(allteams)
}
