#!/usr/bin/env zsh
if [[ $# -ne 2 ]]
then
  print -P "%F{red}Usage:%f ${0} <suffix-1> <suffix-2>"
  exit 1
fi
LHS=$1
RHS=$2
SNAPSHOT_DIR="${HOME}/Dropbox/Shared/Snapshots"
for snapshot in brew cask eclipse gem npm pip
do
  print -P "diff %F{blue}${snapshot} ${LHS} ${RHS}%f ..."
  PREFIX="${SNAPSHOT_DIR}/${snapshot}"
  diff "${PREFIX}${LHS}.txt" "${PREFIX}${RHS}.txt"
done
