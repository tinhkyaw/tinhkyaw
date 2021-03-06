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
brew list --formula > ${SNAPSHOT_DIR}/brew${SUFFIX}.txt
brew list --cask > ${SNAPSHOT_DIR}/cask${SUFFIX}.txt
CASK_EXCLUSIONS="\
asciidocfx\
|celldesigner\
|colloquy\
|lastpass\
|lulu\
|microsoft-auto-update\
|viscosity\
|webex-meetings\
|zoom\
"
brew list --cask | egrep -vi ${CASK_EXCLUSIONS} > ${PKG_DIR}/casks
mas list > ${SNAPSHOT_DIR}/mas${SUFFIX}.txt
gem list > ${SNAPSHOT_DIR}/gem${SUFFIX}.txt
npm ls -g --depth 0 > ${SNAPSHOT_DIR}/npm${SUFFIX}.txt
pip3 freeze --local > ${SNAPSHOT_DIR}/pip3${SUFFIX}.txt
pip3 freeze --local > ${PKG_DIR}/pip3s
conda list > ${SNAPSHOT_DIR}/conda${SUFFIX}.txt
apm list --installed --bare > ${SNAPSHOT_DIR}/atom${SUFFIX}.txt
apm list --installed --bare > ${PKG_DIR}/atom_packages
code --list-extensions --show-versions | sort -d -f \
> ${SNAPSHOT_DIR}/code${SUFFIX}.txt
VSCODE_EXCLUSIONS="\
esbenp.prettier-vscode\
|scala-lang.scala\
|^dart-code.*\
|^docsmsft.docs.*\
|^donjayamanne.*\
|^ms-vscode-remote.remote*\
|^ms-vsliveshare.*\
|^redhat.*\
|^vscjava.vscode*\
|.*better-cpp-syntax$\
|.*better-toml$\
|.*cmake*\
|.*code-spell-checker$\
|.*cpptools$\
|.*cpptools-themes$\
|.*doxdocgen$\
|.*django$\
|.*gitignore$\
|.*gitlens$\
|.*intellicode$\
|.*jinja$\
|.*kubernetes-tools$\
|.*linkcheckmd$\
|.*markdownlint$\
|.*mindaro$\
|.*opa$\
|.*open-in-github$\
|.*project-manager$\
|.*python$\
|.*vscode-pull-request-github$\
|.*vscode-test-explorer$\
|.*vsonline$\
"
VSCODE_INCLUSIONS=".*-pack$"
sort -d -f <(code --list-extensions | egrep ${VSCODE_INCLUSIONS}) \
<(code --list-extensions | egrep -vi ${VSCODE_EXCLUSIONS}) \
> ${PKG_DIR}/vscode_extensions
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version > \
${SNAPSHOT_DIR}/chrome${SUFFIX}.txt
gcloud version | grep -v gcloud > ${SNAPSHOT_DIR}/gcloud${SUFFIX}.txt
cd ${WD}
