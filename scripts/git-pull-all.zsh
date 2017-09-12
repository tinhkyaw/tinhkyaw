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
  if [[ -d ${DIR}/${d} && -d ${DIR}/${d}/.git ]]
  then
    cd ${DIR}/${d}
    if [[ $(git remote) ]]
    then
      print -P "%F{blue}Attempting%f git pull %F{cyan}${d}%f"
      if ! git pull
      then
        print -P "%F{red}Retrying%f git pull --no-rebase %F{cyan}${d}%f"
        git pull --no-rebase
      fi
    else
      print -P "%F{yellow}Skipping%f %F{cyan}${d}%f - no remote set"
    fi
    cd ${DIR}
  else
    print -P "%F{yellow}Skipping%f %F{cyan}${d}%f - not a git directory"
  fi
done
cd ${P}
