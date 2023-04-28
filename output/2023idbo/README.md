# Data Dictionary
This program gives you a lot of data for a given competition, so I figured it'd be good to explain the metrics. 

## Files:
Each heading is based on a type of file created during the script  
i.e. event_team.csv -> 2023vabla_frc2106.csv

### Event_Team.csv
These spreadsheets contain data from individual matches.
- match_number: the match number (qualifier matches only)
- alliance: which alliance the team was on (red/blue)
- team1: team in alliance position 1 (useful for finding climbs/drivers stations)
- team2: team in alliance position 2
- team3: team in alliance position 3
- scores: alliance score in match
- auto_gpp: game-piece points scored during autonomous
- auto_p: points scored in autonomous
- auto_dock: did team dock during auto
- auto_balance: was the docking station level (will show level for non-climbs)
- tele_gpp: teleoperated game-piece points
- tele_p: points scored during teleop
- tele_dock: did team dock/park during auto
- tele_balance: was docking station level

### Event_All.csv
This spreadsheet contains general data compiled from individual team files
- team: self explanatory
- opr: Offensive Power Ranking for a team (estimated contribution per match)
    - useful for making predictions, and tends to be more robust than average match scores due to variance in random alliance partners
    - if negative, it means that team tends to lower the score of their team in matches they are in 
- auto_opr: estimated contribution per match during autonomous
- auto_game_piece_opr: estimated contribution of number of game pieces during autonomous  (count of game pieces, not points)
- count_auto_dock: number of times docked in autonomous
- count_auto_level: number of times team docked in autonomous and scale was also level
- teleop_opr: estimated points contribution during teleop
- teleop_game_piece_opr: estimated contribution of number of game pieces during teleop (this is a count of pieces not points)
    - this can be thought of as estimated number of cycles
- count_tele_dock: number of times docked in teleop
- count_tele_balance: number of times where scale was level when docked during endgame
- auto_teleop_opr_ratio: the ratio of auto_opr to tele_opr
    - i.e. score of 0.32 means 32% of a teams points are scored in autonomous
    - disregard this metric if the score is > 1

## Scouting Insights
Overall, many of these metrics can be useful in scouting, but I think the most useful are:
- opr, auto_opr, tele_opr (estimated points contributions) 
    - get a sense of how good a team is, even if they get bad random alliance partners
    - predict match outcomes
    - get a sense of how good a team is during auto/teleop
- auto_game_piece_opr, teleop_game_piece_opr (estimated cycles)
    - an of estimate of number of pieces a team scores in auto
    - an estimate of number of pieces scored/cycles performed in teleop 
- count_auto_dock, count_tele_dock, count_auto_balance, count_tele_balance
    - how consistently teams can dock in auto/tele
    - how consistently they balance when docking

Using the data in these sheets can help improve scouting by providing additional information, or by (in some cases) reducing scouting load by removing need to keep track of certain actions while live scouting (in 2023 this would be docking since we can get that information from the api).
This allows scouts to focus on other things that we can't directly obtain from apis, namely cycle counts for individual matches (remember opr is just an estimate), and driving skill.

