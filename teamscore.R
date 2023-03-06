# 
# Parses and outputs match statistics for team
#
# @input df: dataframe containing match data
# @input tkey: team key 'frc2106'
#
getTeamData <- function(df, tkey) {
    # initialize vectors
    match_number <- c()
    team <- c()
    scores <- c()
    auto_gpp <- c()
    auto_p <- c()
    auto_dock <- c()
    auto_balance <- c()
    tele_gpp <- c()
    tele_dock <- c()
    tele_p <- c()
    tele_balance <- c()


    # loop through all matches
    for (i in 1:length(df$match_number)) {
        # get alliances on both teams
        keysb <- simplify2array(df$alliances$blue$team_keys[i])
        keysr <- simplify2array(df$alliances$red$team_keys[i])

        # TODO: add sf and f matches?
        if (df$comp_level[i] != "qm") {
            next 
        }

        # keys <- append(keysb, keysr)
        match_number <- append(match_number, df$match_number[i])

        if (tkey %in% keysr) { # red alliance
            # get position: 1/2/3 
            pos <- which(keysr == tkey)
            # make new dataframe for easier indexing
            sb <- df$score_breakdown$red
            team <- append(team, 'red')

            # AUTO
            if (pos == 1) {
                auto_dock <- append(auto_dock, sb$autoChargeStationRobot1[i])
            } else if (pos == 2) {
                auto_dock <- append(auto_dock, sb$autoChargeStationRobot2[i])
            } else if (pos == 3){
                auto_dock <- append(auto_dock, sb$autoChargeStationRobot3[i])
            } else {
                auto_dock <- append(auto_dock, '0')
            }
            auto_balance <- append(auto_balance, sb$autoBridgeState[i])
            auto_gpp <- append(auto_gpp, sb$autoGamePiecePoints[i]) 
            auto_p <- append(auto_p, sb$autoPoints[i])

            # TELEOP
            tele_gpp <- append(tele_gpp, sb$teleopGamePiecePoints[i])
            tele_p <- append(tele_p, sb$teleopPoints[i])
            if (pos == 1) {
                tele_dock <- append(tele_dock, sb$engGameChargeStationRobot1[i])
            } else if (pos == 2) {
                tele_dock <- append(tele_dock, sb$endGameChargeStationRobot2[i])
            } else if (pos == 3){
                tele_dock <- append(tele_dock, sb$endGameChargeStationRobot3[i])
            } else {
                tele_dock <- append(tele_dock, '0')
            }
            tele_balance <- append(tele_balance, sb$endGameBridgeState[i])

            # TOTAL
            scores <- append(scores, df$alliances$red$score[i])

        } else if (tkey %in% keysb) { # blue alliance
            # get position: 1/2/3 
            pos <- which(keysb == tkey)
            # make new dataframe for easier indexing
            sb <- df$score_breakdown$blue
            team <- append(team, 'blue')

            # AUTO
            if (pos == 1) {
                auto_dock <- append(auto_dock, sb$autoChargeStationRobot1[i])
            } else if (pos == 2) {
                auto_dock <- append(auto_dock, sb$autoChargeStationRobot2[i])
            } else if (pos == 3){
                auto_dock <- append(auto_dock, sb$autoChargeStationRobot3[i])
            } else {
                auto_dock <- append(auto_dock, '0')
            }
            auto_balance <- append(auto_balance, sb$autoBridgeState[i])
            auto_gpp <- append(auto_gpp, sb$autoGamePiecePoints[i]) 
            auto_p <- append(auto_p, sb$autoPoints[i])

            # TELEOP
            tele_gpp <- append(tele_gpp, sb$teleopGamePiecePoints[i])
            tele_p <- append(tele_p, sb$teleopPoints[i])
            if (pos == 1) {
                tele_dock <- append(tele_dock, sb$engGameChargeStationRobot1[i])
            } else if (pos == 2) {
                tele_dock <- append(tele_dock, sb$endGameChargeStationRobot2[i])
            } else if (pos == 3){
                tele_dock <- append(tele_dock, sb$endGameChargeStationRobot3[i])
            } else {
                tele_dock <- append(tele_dock, '0')
            }
            tele_balance <- append(tele_balance, sb$endGameBridgeState[i])

            # TOTAL
            scores <- append(scores, df$alliances$blue$score[i])

        }
    }

    # output report
    return(cbind(match_number, team, scores, auto_gpp, auto_p, auto_dock, 
        auto_balance, tele_gpp, tele_p, tele_dock, tele_balance))
    # return(tibble(match_number, team, scores, auto_gpp, auto_p, auto_dock, auto_balance, tele_gpp, tele_p, tele_dock, tele_balance))
}

