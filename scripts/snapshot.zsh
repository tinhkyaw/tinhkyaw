#!/usr/bin/env zsh
if [[ $# -ne 1 ]]; then
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
color=green
print -P "%F{$color}Taking snapshot...%f"
brew list --formula >${SNAPSHOT_DIR}/brew${SUFFIX}.txt
read -r -d '' BREWS_TO_ADD <<EOF
fluid-synth
lepton
luajit
katago
liblinear
EOF
{
  grep -Fvxf \
    <(brew deps --installed | awk -F ':' '{ print $2 }' | sed "s/ /\n/g" | sort -u) \
    <(brew list --formula --full-name -1 | sort)
  echo ${BREWS_TO_ADD}
} | sort -u >${PKG_DIR}/brews
brew list --cask >${SNAPSHOT_DIR}/cask${SUFFIX}.txt
CASKS_TO_IGNORE="\
colloquy\
|lastpass\
|lulu\
|mit-app-inventor\
|ransomwhere\
|viscosity\
|webex-meetings\
|^zoom$\
"
read -r -d '' CASKS_TO_ADD <<EOF
amazon-music
asciidocfx
dmidiplayer
fig
gpower
nautilus
vidl
virtualbox
virtualbox-extension-pack
windscribe
EOF
{
  brew list --cask | egrep -vi ${CASKS_TO_IGNORE}
  echo ${CASKS_TO_ADD}
} | sort -u >${PKG_DIR}/casks
brew tap >${SNAPSHOT_DIR}/tap${SUFFIX}.txt
mas list >${SNAPSHOT_DIR}/mas${SUFFIX}.txt
gem list >${SNAPSHOT_DIR}/gem${SUFFIX}.txt
npm ls --location=global --depth 0 >${SNAPSHOT_DIR}/npm${SUFFIX}.txt
pip3 freeze --local >${SNAPSHOT_DIR}/pip3${SUFFIX}.txt
read -r -d '' PIPS_TO_ADD <<EOF
tensorflow
EOF
{
  grep -Fvxf \
    <(pip3 freeze | cut -d '=' -f1 | cut -d ' ' -f1 | xargs pip show |
      grep -i '^requires:' | awk -F ': ' '{ print $2 }' |
      tr '[:upper:]' '[:lower:]' | sed 's/,/\n/g' | sed 's/ //g' | awk NF |
      sort -u) \
    <(pip3 freeze | cut -d '=' -f1 | cut -d ' ' -f1 |
      tr '[:upper:]' '[:lower:]' | sort -u)
  echo ${PIPS_TO_ADD}
} | sort -u >${PKG_DIR}/pip3s

conda list >${SNAPSHOT_DIR}/conda${SUFFIX}.txt
code --list-extensions --show-versions | sort -d -f \
  >${SNAPSHOT_DIR}/code${SUFFIX}.txt
grep -Fvxf \
  <(egrep -l 'extensionDependencies|extensionPack' \
    ~/.vscode/extensions/*/package.json |
    xargs -I {} jq '.extensionDependencies, .extensionPack' {} |
    jq -sS 'add|sort|unique' |
    jq -r '.[]') \
  <(code --list-extensions | sort -d -f) >${PKG_DIR}/vscode_extensions
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version \
  >${SNAPSHOT_DIR}/chrome${SUFFIX}.txt
gcloud version | grep -v gcloud >${SNAPSHOT_DIR}/gcloud${SUFFIX}.txt
cd ${WD}
