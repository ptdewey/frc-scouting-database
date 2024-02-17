library(magrittr)
library(dplyr)
library(glue)

# @input allteams: input/output dataframe
# @input df: team matches dataframe
# @input team_key: team identifier
# @input event_key: event identifier
# @input output_dir: the directory containing ouput files
get_event_means <- function(allteams, df, opr_df, team_key,
                            event_key, output_dir) {
    # create team csv file
    # TODO: move this somewhere else
    write.csv(df, glue("{output_dir}/{event_key}/{event_key}_{team_key}.csv"))
    # clean out unplayed matches
    df <- df[which(df$scores != -1), ]
    n <- length(df$scores)

    team_row <- which(opr_df$team == team_key)

    allteams <- rbind(allteams, c(team_key,
        opr_df$opr[team_row], opr_df$auto_opr[team_row],
        opr_df$teleop_opr[team_row],
        # opr_df$auto_opr_ratio[team_row],
        opr_df$rp_opr[team_row]
    ))

    cols <- c("team", "opr", "auto_opr",
        # "auto_teleop_rating_ratio",
        "teleop_opr", "rp_rating")
    colnames(allteams) <- cols

    allteams %<>%
        mutate_at(vars(contains("opr")), ~ as.numeric(.)) %>%
        mutate_at(vars(contains("count")), ~ as.integer(.))

    return(allteams)
}
