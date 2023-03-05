#!/bin/zsh

# Get/Update json containing full event match data
curl -X 'GET' \
  'https://www.thebluealliance.com/api/v3/team/frc2106/event/2023vabla/matches' \
  -H 'accept: application/json' \
  -H 'X-TBA-Auth-Key: Fot6bq8bTn0rRRiYAxS1a9kSG3yDhDOq03cn50G54MmRQfT448faHNGokaHIrhli' > data/vabla_matches.json

