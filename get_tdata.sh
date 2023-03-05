#!/bin/zsh

# get match data for all teams in teams.txt
for TEAMKEY in `cat data/teams.txt`; do
    echo "Fetching data for $TEAMKEY..."
    curl -X 'GET' \
      "https://www.thebluealliance.com/api/v3/team/{$TEAMKEY}/event/2023vabla/matches" \
      -H 'accept: application/json' \
      -H 'X-TBA-Auth-Key: Fot6bq8bTn0rRRiYAxS1a9kSG3yDhDOq03cn50G54MmRQfT448faHNGokaHIrhli' > input/m_$TEAMKEY.json
done

