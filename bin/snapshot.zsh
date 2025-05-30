#!/usr/bin/env zsh
if [[ $# -ne 1 ]]; then
  print -P "%F{red}Usage:%f ${0} <suffix>"
  exit 1
fi
SUFFIX="${1}"
SNAPSHOT_DIR="${HOME}/Dropbox/Shared/Snapshots"
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}" || exit
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
LIST_DIR="${GIT_ROOT_DIR}/lists"
color=blue
print -P "%F{${color}}Taking snapshot...%f"
brew list --formula >"${SNAPSHOT_DIR}/brew${SUFFIX}.txt"
BREWS_TO_IGNORE="\
fluid-synth\
|katago\
|python@3.9\
"
{
  grep -Fvxf \
    <(brew deps --installed |
      awk -F ':' '{ print $2 }' |
      tr ' ' '\n' |
      sort -u) \
    <(brew list --formula --full-name -1 |
      sort) |
    grep -Evi ${BREWS_TO_IGNORE}
} | sort -u >"${LIST_DIR}/brews.txt"
brew list --cask >"${SNAPSHOT_DIR}/cask${SUFFIX}.txt"
CASKS_TO_IGNORE="\
microsoft-teams\
|tunnelblick\
|^zoom\
"
# read -r -d '' CASKS_TO_ADD <<EOF
# EOF
{
  brew list --cask | grep -Evi ${CASKS_TO_IGNORE}
  # echo "${CASKS_TO_ADD}"
} | sort -u >"${LIST_DIR}/casks.txt"
brew tap >"${SNAPSHOT_DIR}/tap${SUFFIX}.txt"
mas list >"${SNAPSHOT_DIR}/mas${SUFFIX}.txt"
gem list >"${SNAPSHOT_DIR}/gem${SUFFIX}.txt"
npm ls -g >"${SNAPSHOT_DIR}/npm${SUFFIX}.txt"
(npm ls -g -p |
  grep node_modules |
  xargs basename) >"${LIST_DIR}/npms.txt"
uv tool list >"${SNAPSHOT_DIR}/uv${SUFFIX}.txt"
("${HOMEBREW_PREFIX}"/anaconda3/bin/conda list \
  -p "${HOMEBREW_PREFIX}"/anaconda3 --explicit |
  grep -v '^[#@]' |
  xargs -I {} basename {} |
  gsed -e 's/.conda\|.tar.bz2//g' |
  sort -u) \
  >"${SNAPSHOT_DIR}/conda${SUFFIX}.txt"
(conda list -n base --explicit |
  grep -v '^[#@]' |
  xargs -I {} basename {} |
  gsed -e 's/.conda\|.tar.bz2//g' |
  sort -u) \
  >"${SNAPSHOT_DIR}/miniforge${SUFFIX}.txt"
code --list-extensions --show-versions | sort -d -f \
  >"${SNAPSHOT_DIR}/code${SUFFIX}.txt"
cursor --list-extensions --show-versions | sort -d -f \
  >"${SNAPSHOT_DIR}/cursor${SUFFIX}.txt"
windsurf --list-extensions --show-versions | sort -d -f \
  >"${SNAPSHOT_DIR}/windsurf${SUFFIX}.txt"
grep -Fvxf \
  <(grep -El 'extensionDependencies|extensionPack' \
    "${HOME}"/.vscode/extensions/*/package.json |
    xargs -I {} jq '.extensionDependencies, .extensionPack' {} |
    jq -sS 'add|sort|unique' |
    jq -r '.[]') \
  <(code --list-extensions | sort -d -f) >"${LIST_DIR}/codes.txt"
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version \
  >"${SNAPSHOT_DIR}/chrome${SUFFIX}.txt"
gcloud version | grep -v gcloud >"${SNAPSHOT_DIR}/gcloud${SUFFIX}.txt"
cp "${HOME}"/.mrconfig "${SNAPSHOT_DIR}/mr${SUFFIX}.txt"
cpan -l >"${SNAPSHOT_DIR}/cpan${SUFFIX}.txt"
print -P "%F{${color}}$(date)%f"
cd "${WD}" || exit
