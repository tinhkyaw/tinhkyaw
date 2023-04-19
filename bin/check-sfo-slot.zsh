#!/usr/bin/env zsh
LOCATION_ID=5446
URL="https://ttp.cbp.dhs.gov/schedulerapi/slot-availability?locationId=${LOCATION_ID}"
while true; do
  if http $URL | jq -e '.availableSlots != []' &>/dev/null; then
    http $URL | jq '.availableSlots[0]'
    tput bel
  else
    echo -ne '.'
  fi
done
