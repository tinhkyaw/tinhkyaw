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
      echo -e "\e[94mAttempting \e[39mgit pull \e[96m$d\e[39m"
      if ! git pull
      then
        echo -e "\e[91mRetrying \e[39mgit pull --no-rebase \e[96m$d\e[39m"
        git pull --no-rebase
      fi
    fi
    cd ${DIR}
  fi
done
cd ${P}
