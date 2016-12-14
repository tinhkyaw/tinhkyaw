#!/usr/bin/env zsh
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
  if [ -d ${DIR}/${d} ]
  then
    cd ${DIR}/${d}
    if [ -d .git ]
    then
      print -P "%F{blue}Attempting%f git pull %F{cyan}${d}%f"
      if ! git pull
      then
        print -P "%F{red}Retrying%f git pull --no-rebase %F{cyan}${d}%f"
        git pull --no-rebase
      fi
    fi
    cd ${DIR}
  fi
done
cd ${P}
