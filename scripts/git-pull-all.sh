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
    [ -d .git ] && echo "Attempting to pull $d" && git pull
    cd ${DIR}
  fi
done
cd ${P}
