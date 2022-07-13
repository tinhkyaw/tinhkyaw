#!/usr/bin/env zsh
P=$(pwd)
if [ "$#" -lt 1 ]
then
  DIR="${P}"
else
  DIR="${1}"
fi
for d in $(find ${DIR} -name '.git' | sort)
do
  gr=${d%?????}
  cd ${gr}
  if [[ $(git remote) ]]
  then
    if (cd "$(git rev-parse --show-toplevel)/.." &&
        git rev-parse --is-inside-work-tree 2>/dev/null) | grep -q true
    then
      print -P "%F{yellow}Skipping%f %F{cyan}${gr}%f - submodule detected!"
    else
      print -P "%F{blue}Attempting%f git pull %F{cyan}${gr}%f"
      if ! git pull
      then
        print -P "%F{red}Retrying%f git pull --no-rebase %F{cyan}${gr}%f"
        git pull --no-rebase
      fi
    fi
  else
    print -P "%F{yellow}Skipping%f %F{cyan}${gr}%f - no remote set!"
  fi
done
cd ${P}
