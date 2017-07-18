#!/usr/bin/env zsh
if [[ $# -ne 1 ]]
then
  print -P "%F{red}Usage:%f ${0} <suffix>"
  exit 1
fi
SUFFIX="${1}"
SNAPSHOT_DIR="${HOME}/Dropbox/Shared/Snapshots"
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "${0}")")
cd ${DIR}
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
PKG_DIR="${GIT_ROOT_DIR}/packages"
brew list > ${SNAPSHOT_DIR}/brew${SUFFIX}.txt
brew cask list > ${SNAPSHOT_DIR}/cask${SUFFIX}.txt
if [ "${SUFFIX}" = "w" ]
then
  brew cask list > ${PKG_DIR}/min_casks
else
  brew cask list > ${PKG_DIR}/casks
fi
gem list > ${SNAPSHOT_DIR}/gem${SUFFIX}.txt
npm ls -g --depth 0 > ${SNAPSHOT_DIR}/npm${SUFFIX}.txt
pip2 freeze --local > ${SNAPSHOT_DIR}/pip${SUFFIX}.txt
pip2 freeze --local > ${PKG_DIR}/pips
cd ${WD}
