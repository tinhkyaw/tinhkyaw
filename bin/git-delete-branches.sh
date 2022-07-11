#!/usr/bin/env bash
P=$(pwd)
if [ "$#" -lt 1 ]; then
  DIR="${P}"
else
  DIR="${1}"
fi
cd "${DIR}" || exit
my_branches=$(
  git for-each-ref --sort=-committerdate \
    --format="%(committerdate:short) %(refname:short) %(authorname)" \
    "$(git branch -r | grep -v HEAD | sed -e 's#^ *#refs/remotes/#')" |
    grep Tin |
    cut -f 2 -d ' '
)
for branch in $my_branches; do
  cmd="git push origin --delete ${branch/origin\//}"
  echo "$cmd"
  $cmd
done
cd "${P}" || exit
