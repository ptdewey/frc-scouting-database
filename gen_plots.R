source("imports.R")

event_keys <- c("2023arc", "2023cur", "2023dal",
    "2023gal", "2023hop", "2023joh", "2023mil", "2023new"
)

for (event_key in event_keys) {
    df <- read_csv(glue("output/{event_key}/{event_key}_opr.csv"))
    df %<>% rename(opr_rank = names(.)[1])
    assign(glue("df_{event_key}"), df)
}

png("output/plots/divisions_opr.png", width = 1280, height = 720)
ggplot() +
    geom_line(data = df_2023arc, aes(opr_rank, opr, col = "archimedes")) +
    geom_line(data = df_2023cur, aes(opr_rank, opr, col = "curie")) +
    geom_line(data = df_2023dal, aes(opr_rank, opr, col = "daly")) +
    geom_line(data = df_2023gal, aes(opr_rank, opr, col = "galileo")) +
    geom_line(data = df_2023hop, aes(opr_rank, opr, col = "hopper")) +
    geom_line(data = df_2023joh, aes(opr_rank, opr, col = "johnson")) +
    geom_line(data = df_2023mil, aes(opr_rank, opr, col = "milstein")) +
    geom_line(data = df_2023new, aes(opr_rank, opr, col = "newton")) +
    ylab("opr") + xlab("opr ranking") + ggtitle("opr ratings by division")
dev.off()

