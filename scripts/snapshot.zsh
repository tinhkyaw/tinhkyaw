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
CASK_EXCLUSIONS='google-drive-file-stream'
brew cask list | egrep -vi ${CASK_EXCLUSIONS} > ${PKG_DIR}/casks
gem list > ${SNAPSHOT_DIR}/gem${SUFFIX}.txt
npm ls -g --depth 0 > ${SNAPSHOT_DIR}/npm${SUFFIX}.txt
PIP_EXCLUSIONS='gdal|tbb'
if command -v pip2 &> /dev/null
then
  pip2 freeze --local > ${SNAPSHOT_DIR}/pip2${SUFFIX}.txt
  pip2 freeze --local | egrep -vi ${PIP_EXCLUSIONS} > ${PKG_DIR}/pip2s
fi
pip3 freeze --local > ${SNAPSHOT_DIR}/pip3${SUFFIX}.txt
pip3 freeze --local | egrep -vi ${PIP_EXCLUSIONS} > ${PKG_DIR}/pip3s
conda list > ${SNAPSHOT_DIR}/conda${SUFFIX}.txt
apm list --installed --bare > ${SNAPSHOT_DIR}/atom${SUFFIX}.txt
apm list --installed --bare > ${PKG_DIR}/atom_packages
code --list-extensions --show-versions | sort > ${SNAPSHOT_DIR}/code${SUFFIX}.txt
VSCODE_EXCLUSIONS='ms-python.python|redhat.java|redhat.vscode-yaml|vscjava.vscode-java-debug|ms-docfx.docfx|docsmsft.docs-markdown|DavidAnson.vscode-markdownlint'
code --list-extensions | egrep -vi ${VSCODE_EXCLUSIONS} | sort > ${PKG_DIR}/vscode_extensions
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version > ${SNAPSHOT_DIR}/chrome${SUFFIX}.txt
cd ${WD}
