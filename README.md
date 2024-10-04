## Use V2 Instead

The scouting system rewrite (v2) is feature-complete with v1 now and should be used instead. ([frc-scouting-database-v2](https://github.com/ptdewey/frc-scouting-database-v2))

---

## FRC Event Modeling:

Welcome to a project I made to help with scouting in the First Robotics Competition.  
I am a college student studying data science, and I originally made this for my old team 2106.  
While this code was originally created for the 2023 season, it has been adapted to be year agnostic, allowing (hypothetically) use for any season.

## How to Use:


Event statistics:
1. Install [Dependencies](#Dependencies)
2. Change directory into [stats-app]
3. Rename `example.env` to `.env` and add your Blue Alliance api key
4. Run `Rscript main.R {event_key}` from the command line or in [RStudio](https://posit.co/downloads/) 
5. Your output csv files can be found within the `output/{event_name}` directory

Predictions:
1. Change directory into [prediction-model](prediction-model/)
2. Modify event keys list in [run_preds.R](run_preds.R) as desired
3. Run `Rscript run_preds.R`
5. Your output csv files can be found within the `output/predictions/{time-event-key}` directory

To run the discord exporter:
1. Create a new `.env` file in [exporter-app](exporter-app/) containing a valid discord bot token (`DISCORD_BOT_TOKEN=your-token-here`), and a valid discord channel ID (`DISCORD_CHANNEL_ID=your-channel`)
3. Change directory into [exporter-app](exporter-app/)
2. Run `go mod download` to fetch required packages
3. Run `go run main.go`, and the bot will be running
4. Send a message to the chosen channel containing ":EventsGet event_key" for a desired event, or 'all' for all current events.  

Note that the exporter bot is scheduled to automatically send event data to the chosen channel once every hour from 8am to 8pm, on Saturdays and Sundays. This behavior can be configured in [main.go](exporter-app/main.go)

## Dependencies:

Core application:

| Name              | Version    |
| ------------------|------------|
| R                 | >= 4.2.2   |
| tidyverse         | >= 1.3.2   |
| dplyr             | >= 1.1.0   |
| ggplot2           | >= 3.4.4   | 
| jsonlite          | >= 1.8.4   |
| glue              | >= 1.7.0   |


Automated export of output files:

| Name              | Version    |
| ------------------|------------|
| Go                | >= 1.22.0  |


Powered by [The Blue Alliance](https://thebluealliance.com/)

<!-- TODO: add Go dependecies, update R dependencies -->
<!-- TODO: rework dir structure, move R stuff to subdir -->
<!-- TODO: change location of where predictions are output to? -->
<!-- TODO: change location of predictions source files -->
