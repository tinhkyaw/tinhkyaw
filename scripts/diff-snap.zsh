#!/usr/bin/env zsh
if [[ $# -ne 2 ]]
then
  print -P "%F{red}Usage:%f ${0} <suffix-1> <suffix-2>"
  exit 1
fi
SUFFIX1=$1
SUFFIX2=$2
SNAPSHOT_DIR="${HOME}/Dropbox/Shared/Snapshots"
for snapshot in brew cask code eclipse gem intellij npm pip2 pip3 pycharm
do
  FILE1="${snapshot}${SUFFIX1}.txt"
  FILE2="${snapshot}${SUFFIX2}.txt"
  LHS="${SNAPSHOT_DIR}/${FILE1}"
  RHS="${SNAPSHOT_DIR}/${FILE2}"
  if ! diff "$LHS" "$RHS" &> /dev/null
  then
    print -P "%F{red}diff%f %F{blue}${FILE1} ${FILE2}%f"
    diff "$LHS" "$RHS"
  else
    print -P "%F{green}No diff%f for %F{blue}${FILE1} ${FILE2}%f"
  fi
done
