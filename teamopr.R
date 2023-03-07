# calculate expected team contribution
# @input df: all event matches dataframe from eventmatches.R
# @input event_teams: team key 'frc216'
getOpr <- function(df, event_teams) {
    # remove unplayed matches
    df <- df[which(df$r_score != -1),]
    # remove non-qualifying matches (not sure if this should be done but tba does it)
    df <- df[which(df$comp_level == 'qm'),]

    # make matrix of red/blue alliances
    alliances <- rbind(cbind(df$r1, df$r2, df$r3), cbind(df$b1, df$b2, df$b3))

    # create scores vector
    score <- c(df$r_score, df$b_score)
    auto_score <- c(df$r_auto_score, df$b_auto_score)
    tele_score <- c(df$r_teleop_score, df$b_teleop_score)

    # create design matrix
    X <- matrix(0, nrow=length(df$match_number)*2, ncol = length(event_teams))
    for (i in 1:(length(df$match_number)*2)) {
        X[i, which(event_teams %in% alliances[i,])] = 1
    }

    # solve the ls system
    opr <- solve(t(X) %*% X) %*% (t(X) %*% score)
    auto_opr <- solve(t(X) %*% X) %*% (t(X) %*% auto_score)
    tele_opr <- solve(t(X) %*% X) %*% (t(X) %*% tele_score)
    auto_ratio <- auto_opr / opr

    team_contrib <- data.frame(event_teams, opr, auto_opr, tele_opr, auto_ratio)
    colnames(team_contrib) <- c('team', 'opr', 'auto_opr', 'teleop_opr', 'auto_opr_%')
    return(team_contrib %>% arrange(desc(opr)))
}

