library(tibble)
library(glue)

# create dataframe containing all matches from event
# @input df: raw event matches dataframe from getEventMatchesRaw()
# @input team_key: team key (i.e. 'frc254')
getTeamMatches <- function(df, team_key) {
    # get alliances
    keysr <- as.data.frame(t(simplify2array(df$alliances$red$team_keys)))
    keysb <- as.data.frame(t(simplify2array(df$alliances$blue$team_keys)))

    # get match numbers where team appears
    match_numbers <- sort(c(which(team_key == keysb[, 1]),
        which(team_key == keysb[, 2]), which(team_key == keysb[, 3]),
        which(team_key == keysr[, 1]), which(team_key == keysr[, 2]),
        which(team_key == keysr[, 3])))

    oldw <- getOption("warn")
    options(warn = -1)
    out <- df[match_numbers, ] %>%
        getTeamData(team_key) %>%
        as.data.frame()
    options(warn = oldw)

    return(out)
}


# create dataframe containing match numbers a team is in, teammates,
#and position index
# @input df: raw event matches dataframe from getEventMatchesRaw()
# @input team_key: team key (i.e. 'frc254')
get_team_index <- function(df, team_key) {
    out <- tibble()
    keysr <- as.data.frame(t(simplify2array(df$alliances$red$team_keys)))
    keysb <- as.data.frame(t(simplify2array(df$alliances$blue$team_keys)))

    # get match numbers where team appears
    match_numbers <- sort(c(which(team_key == keysb[, 1]),
        which(team_key == keysb[, 2]), which(team_key == keysb[, 3]),
        which(team_key == keysr[, 1]), which(team_key == keysr[, 2]),
        which(team_key == keysr[, 3])))

    # subset teamkeys
    keysr <- keysr[match_numbers, ]
    keysb <- keysb[match_numbers, ]
    idx <- c()
    color <- c()
    for (i in seq_along(match_numbers)) {
        if (team_key %in% keysr[i, ]) {
            pos <- which(keysr[i, ] == team_key)
            idx <- append(idx, pos)
            color <- append(color, "r")
        } else if (team_key %in% keysb[i, ]) {
            pos <- which(keysb[i, ] == team_key)
            idx <- append(idx, pos)
            color <- append(color, "b")
        }
    }
    out <- tibble(
        match_number = match_numbers,
        comp_level = df[match_numbers, ]$comp_level,
        team_alliance = color,
        team_index = idx,
        r1 = keysr[, 1],
        r2 = keysr[, 2],
        r3 = keysr[, 3],
        b1 = keysr[, 1],
        b2 = keysr[, 2],
        b3 = keysr[, 3]
    )
    return(out)
}

