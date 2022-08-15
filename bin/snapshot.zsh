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
LIST_DIR="${GIT_ROOT_DIR}/lists"
color=green
print -P "%F{${color}}Taking snapshot...%f"
brew list --formula >"${SNAPSHOT_DIR}/brew${SUFFIX}.txt"
read -r -d '' BREWS_TO_ADD <<EOF
fluid-synth
lepton
luajit
katago
liblinear
EOF
{
  grep -Fvxf \
    <(brew deps --installed |
      awk -F ':' '{ print $2 }' |
      tr ' ' '\n' |
      sort -u) \
    <(brew list --formula --full-name -1 | sort)
  echo ${BREWS_TO_ADD}
} | sort -u >"${LIST_DIR}/brews.txt"
brew list --cask >"${SNAPSHOT_DIR}/cask${SUFFIX}.txt"
CASKS_TO_IGNORE="\
krisp\
|lastpass\
|^zoom$\
"
read -r -d '' CASKS_TO_ADD <<EOF
amazon-music
dmidiplayer
fig
gpower
nautilus
vidl
virtualbox
virtualbox-extension-pack
EOF
{
  brew list --cask | egrep -vi ${CASKS_TO_IGNORE}
  echo ${CASKS_TO_ADD}
} | sort -u >"${LIST_DIR}/casks.txt"
brew tap >"${SNAPSHOT_DIR}/tap${SUFFIX}.txt"
mas list >"${SNAPSHOT_DIR}/mas${SUFFIX}.txt"
gem list >"${SNAPSHOT_DIR}/gem${SUFFIX}.txt"
npm ls -g >"${SNAPSHOT_DIR}/npm${SUFFIX}.txt"
npm ls -g -p |
  grep node_modules |
  xargs basename >"${LIST_DIR}/npms.txt"
pip3 freeze --local >"${SNAPSHOT_DIR}/pip3${SUFFIX}.txt"
read -r -d '' PIPS_TO_ADD <<EOF
tensorflow
EOF
p=$(
  grep -Fvxf \
    <(
      pip3 freeze |
        cut -d '=' -f1 |
        cut -d ' ' -f1 |
        xargs pip3 show |
        grep -i '^requires:' |
        awk -F ': ' '{ print $2 }' |
        tr '[:upper:]' '[:lower:]' |
        tr ',' '\n' |
        sed 's/ //g' |
        awk NF |
        sort -u
    ) \
    <(
      pip3 freeze |
        cut -d '=' -f1 |
        cut -d ' ' -f1 |
        tr '[:upper:]' '[:lower:]' |
        sort -u
    )
)
d=$(
  echo $p |
    xargs pip3 show |
    grep -i '^required-by:' |
    grep -in '^required-by: [a-z]' |
    cut -d ':' -f1 |
    gsed -z 's/\n/d;/g'
)
{
  echo $p | sed -e "$d"
  echo ${PIPS_TO_ADD}
} | sort -u >"${LIST_DIR}/pip3s.txt"
"${HOMEBREW_PREFIX}"/anaconda3/bin/conda list \
  -p "${HOMEBREW_PREFIX}"/anaconda3 --explicit \
  >"${SNAPSHOT_DIR}/conda${SUFFIX}.txt"
conda list -n base --explicit >"${SNAPSHOT_DIR}/miniforge${SUFFIX}.txt"
code --list-extensions --show-versions | sort -d -f \
  >"${SNAPSHOT_DIR}/code${SUFFIX}.txt"
grep -Fvxf \
  <(egrep -l 'extensionDependencies|extensionPack' \
    "${HOME}"/.vscode/extensions/*/package.json |
    xargs -I {} jq '.extensionDependencies, .extensionPack' {} |
    jq -sS 'add|sort|unique' |
    jq -r '.[]') \
  <(code --list-extensions | sort -d -f) >"${LIST_DIR}/codes.txt"
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version \
  >"${SNAPSHOT_DIR}/chrome${SUFFIX}.txt"
gcloud version | grep -v gcloud >"${SNAPSHOT_DIR}/gcloud${SUFFIX}.txt"
cat "${HOME}"/.mrconfig >"${SNAPSHOT_DIR}/mr${SUFFIX}.txt"
cpan -l >"${SNAPSHOT_DIR}/cpan${SUFFIX}.txt"
cd ${WD}
