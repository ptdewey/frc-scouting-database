library(tibble)
library(magrittr)
library(dplyr)

# calculate expected team contribution
# @input df: all event matches dataframe from eventmatches.R
# @input event_teams: team key "frc216"
getOpr <- function(df, event_teams) {
    # remove unplayed matches
    df <- df[which(df$r_score != -1), ]
    # remove non-qualifying matches
    df <- df[which(df$comp_level == "qm"), ]

    # make matrix of red/blue alliances
    alliances <- rbind(cbind(df$r1, df$r2, df$r3), cbind(df$b1, df$b2, df$b3))

    # remove any teams with no matches played
    missing <- which(!(event_teams %in% alliances))
    if (length(missing) != 0) {
        event_teams <- event_teams[-missing]
    }

    # create scores vector
    score <- c(df$r_score, df$b_score)
    auto_score <- c(df$r_auto_score, df$b_auto_score)
    tele_score <- c(df$r_teleop_score, df$b_teleop_score)
    auto_gpc <- c(df$r_auto_gpc, df$b_auto_gpc)
    tele_gpc <- c(df$r_tele_gpc, df$b_tele_gpc)
    rp <- c(df$r_rp, df$b_rp)

    # create design matrix
    X <- matrix(0, nrow = length(df$match_number) * 2,
        ncol = length(event_teams)
    )
    for (i in 1:(length(df$match_number) * 2)) {
        X[i, which(event_teams %in% alliances[i, ])] <- 1
    }

    # solve the ls system
    opr <- solve(t(X) %*% X) %*% (t(X) %*% score)
    auto_opr <- solve(t(X) %*% X) %*% (t(X) %*% auto_score)
    tele_opr <- solve(t(X) %*% X) %*% (t(X) %*% tele_score)
    auto_ratio <- auto_opr / opr
    auto_gp_opr <- solve(t(X) %*% X) %*% (t(X) %*% auto_gpc)
    tele_gp_opr <- solve(t(X) %*% X) %*% (t(X) %*% tele_gpc)
    rp_opr <- solve(t(X) %*% X) %*% (t(X) %*% rp)


    team_contrib <- data.frame(event_teams, opr, auto_opr, tele_opr, auto_ratio,
        auto_gp_opr, tele_gp_opr, rp_opr)
    colnames(team_contrib) <- c("team", "opr", "auto_opr", "teleop_opr",
        "auto_opr_ratio", "auto_gpc_opr", "tele_gpc_opr", "rp_opr")
    return(team_contrib %>% arrange(desc(opr)))
}

# get standard deviation of opr ratings per team
# remove one match then calculate opr, repeat for each match
# then calculate sd of those ratings
# @input df: dataframe from getEventMatches()
# @input event_teams: list of teams at event
get_opr_sd <- function(df, event_teams) {

    # remove unplayed matches
    df %<>% filter(r_score != -1)
    # remove non-qualifying matches
    df %<>% filter(comp_level == "qm")

    # remove any teams with no matches played
    alliances <- rbind(cbind(df$r1, df$r2, df$r3), cbind(df$b1, df$b2, df$b3))
    missing <- which(!(event_teams %in% alliances))
    if (length(missing) != 0) {
        event_teams <- event_teams[-missing]
    }
    # create intermediary output dataframe
    loo_opr <- tibble(.rows = length(event_teams))

    # for each match drop it and calculate opr
    for (drop_match in df$match_number) {
        drop_df <- df %>% filter(match_number != drop_match)
        score <- c(drop_df$r_score, drop_df$b_score)
        alliances <- rbind(cbind(drop_df$r1, drop_df$r2, drop_df$r3),
            cbind(drop_df$b1, drop_df$b2, drop_df$b3))

        # set up design matrix
        X <- matrix(0, nrow = length(drop_df$match_number) * 2,
            ncol = length(event_teams)
        )
        for (i in 1:(length(drop_df$match_number) * 2)) {
            X[i, which(event_teams %in% alliances[i, ])] <- 1
        }

        # solve system of equations
        opr <- solve(t(X) %*% X) %*% (t(X) %*% score)
        loo_opr %<>% cbind(opr)
    }
    opr_sd <- c()
    for (i in seq_along(event_teams)) {
        match_nums <- get_team_match_numbers(df, event_teams[i])
        opr_sd <- append(opr_sd, sd(loo_opr[i, match_nums]))
    }
    team_opr_df <- tibble(
        team = event_teams,
        opr_sd = opr_sd
    )
    return(team_opr_df)
}

