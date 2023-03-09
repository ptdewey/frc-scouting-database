# @input allteams: input/output dataframe
# @input df: team matches dataframe
# @input team_key: team identifier
# @input event_key: event identifier
getEventMeans <- function(allteams, df, opr_df, team_key, event_key) {
    # create team csv file
    # TODO: move this somewhere else
    write.csv(df, glue("output/{event_key}/{event_key}_{team_key}.csv"))
    # clean out unplayed matches
    df <- df[which(df$scores != -1),]
    auto_dock <- length(which(df$auto_dock == 'Docked'))
    auto_balance <- length(which(df$auto_balance == 'Level' & df$auto_dock == 'Docked'))
    tele_dock <- length(which(df$tele_dock == 'Docked'))
    tele_balance <- length(which(df$tele_balance == 'Level' & df$tele_dock == 'Docked'))

    team_row <- which(opr_df$team == team_key)

    allteams <- rbind(allteams, c(team_key, 
        opr_df$opr[team_row], opr_df$auto_opr[team_row], opr_df$auto_gpc_opr[team_row],
        auto_dock, auto_balance, opr_df$teleop_opr[team_row], 
        opr_df$tele_gpc_opr[team_row], tele_dock, tele_balance,
        opr_df$auto_opr_ratio[team_row]))

    cols <- c('team', 'opr', 'auto_opr', 'auto_game_piece_opr', 
        'count_auto_dock', 'count_auto_level', 'teleop_opr', 
        'teleop_game_piece_opr', 'count_tele_dock', 'count_tele_balance',
        'auto_teleop_opr_ratio')
    colnames(allteams) <- cols

    return(allteams)
}
