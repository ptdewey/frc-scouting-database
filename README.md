## FRC Event Modeling 2023:

Welcome to a project I made to help with scouting for the 2023 First Robotics Competition.  
I am a college student studying data science, and I originally made this for my old team 2106.  

## How to Use:

1. Clone repository
2. Install [Dependencies](#Dependencies)
3. Rename `example.env` to `.env` and add your Blue Alliance api key
4. Run ```Rscript main.R {event_key}``` from the command line or in [RStudio](https://posit.co/downloads/) 
5. Your output csv files can be found within the `output/{event_name}` directory

If you would like a Google Colab/Jupyter Notebook implementation I can make one available upon request.  

## Dependencies:

| Name              | Version    |
| ------------------|------------|
| R                 | >= 4.2.2   |
| tidyverse         | >= 1.3.2   |
| dplyr             | >= 1.1.0   |
| jsonlite          | >= 1.8.4   |

Powered by [The Blue Alliance](https://thebluealliance.com/)
