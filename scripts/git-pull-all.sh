#!/usr/bin/env bash
P=$(pwd)
if [ "$#" -lt 1 ]
then
  DIR="${P}"
else
  DIR="${1}"
fi
cd ${DIR}
for d in $(ls)
do
  if [ -d ${DIR}/$d ]
  then
    cd ${DIR}/$d
    if [ -d .git ]
    then
      echo "Attempting to pull $d"
      if ! git pull
      then
        echo "Retrying with git pull --no-rebase"
        git pull --no-rebase
      fi
    fi
    cd ${DIR}
  fi
done
cd ${P}
