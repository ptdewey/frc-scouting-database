# Parses and outputs match statistics for team
#
# @input df: dataframe containing match data
# @input tkey: team key 'frc2106'
#
get_team_data <- function(df, tkey) {
    # initialize vectors
    match_number <- c()
    scores <- c()
    auto_gpp <- c()
    auto_p <- c()
    tele_gpp <- c()
    tele_p <- c()
    alliance <- matrix(nrow = 0, ncol = 4)
    rp <- c()
    colnames(alliance) <- c("alliance", "team1", "team2", "team3")

    # loop through all matches
    for (i in seq_along(df$match_number)) {
        # get alliances on both teams
        keysb <- simplify2array(df$alliances$blue$team_keys[i])
        keysr <- simplify2array(df$alliances$red$team_keys[i])

        # TODO: add sf and f matches?
        if (df$comp_level[i] != "qm") {
            next
        }

        match_number <- append(match_number, df$match_number[i])

        # TODO: add wins, opponents, opp scores
        if (tkey %in% keysr) { # red alliance
            # get position: 1/2/3
            pos <- which(keysr == tkey)
            alliance <- rbind(alliance, c("red", keysr))
            # make new dataframe for easier indexing
            sb <- df$score_breakdown$red

            # ranking points
            rp <- append(rp, sb$rp[i])

            # AUTO
            auto_gpp <- append(auto_gpp, sb$autoGamePiecePoints[i])
            auto_p <- append(auto_p, sb$autoPoints[i])

            # TELEOP
            tele_gpp <- append(tele_gpp, sb$teleopGamePiecePoints[i])
            tele_p <- append(tele_p, sb$teleopPoints[i])

            # TOTAL
            scores <- append(scores, df$alliances$red$score[i])

        } else if (tkey %in% keysb) { # blue alliance
            # get position: 1/2/3
            pos <- which(keysb == tkey)
            alliance <- rbind(alliance, c("blue", keysb))
            # make new dataframe for easier indexing
            sb <- df$score_breakdown$blue

            # ranking points
            rp <- append(rp, sb$rp[i])

            # AUTO
            auto_gpp <- append(auto_gpp, sb$autoGamePiecePoints[i])
            auto_p <- append(auto_p, sb$autoPoints[i])

            # TELEOP
            tele_gpp <- append(tele_gpp, sb$teleopGamePiecePoints[i])
            tele_p <- append(tele_p, sb$teleopPoints[i])

            # TOTAL
            scores <- append(scores, df$alliances$blue$score[i])
        }
    }

    # output report
    return(as.data.frame(cbind(match_number, alliance, scores,
        auto_gpp, auto_p, tele_gpp, tele_p, rp))
    )
}

