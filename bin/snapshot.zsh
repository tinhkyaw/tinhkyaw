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
^corretto\
|krisp\
|lastpass\
|^zoom\
"
read -r -d '' CASKS_TO_ADD <<EOF
amazon-music
dmidiplayer
nautilus
podolski
triplecheese
virtualbox
virtualbox-extension-pack
EOF
{
  brew list --cask | grep -Evi ${CASKS_TO_IGNORE}
  echo "${CASKS_TO_ADD}"
} | sort -u >"${LIST_DIR}/casks.txt"
brew tap >"${SNAPSHOT_DIR}/tap${SUFFIX}.txt"
mas list >"${SNAPSHOT_DIR}/mas${SUFFIX}.txt"
gem list >"${SNAPSHOT_DIR}/gem${SUFFIX}.txt"
npm ls -g >"${SNAPSHOT_DIR}/npm${SUFFIX}.txt"
(npm ls -g -p |
  grep node_modules |
  xargs basename) >"${LIST_DIR}/npms.txt"
"${HOMEBREW_PREFIX}"/bin/pip3 freeze >"${SNAPSHOT_DIR}/pip3${SUFFIX}.txt"
PIPS_TO_IGNORE="\
jupyter|\
pygobject|\
pyqt|\
qscintilla|\
fuzzytm|\
gensim|\
smart-open|\
tensorflow\
"
if (( !${+commands[pipdeptree]} )); then
  "${HOMEBREW_PREFIX}"/bin/pip3 install pipdeptree
fi
p=$(
  "${HOMEBREW_PREFIX}"/bin/pipdeptree --json-tree |
    jq -r 'map(.package_name) | .[]' |
    tr '[:upper:]' '[:lower:]' |
    sort -u
)
q=$(
  grep -Fvxf \
    <(brew info --json=v1 --installed |
      jq -r \
        'map(select((.dependencies + .build_dependencies +
         .test_dependencies)[] | contains("python"))) | .[] .name' |
      sort -u) \
    <(echo "$p")
)
{
  echo "$q" |
    grep -Evi ${PIPS_TO_IGNORE}
} | sort -u >"${LIST_DIR}/pip3s.txt"
("${HOMEBREW_PREFIX}"/anaconda3/bin/conda list \
  -p "${HOMEBREW_PREFIX}"/anaconda3 --explicit |
  grep -v '^[#@]' |
  xargs -I {} basename {} |
  gsed -e 's/.conda\|.tar.bz2//g' |
  sort -u) \
  >"${SNAPSHOT_DIR}/conda${SUFFIX}.txt"
("${HOMEBREW_PREFIX}"/bin/conda list -n base --explicit |
  grep -v '^[#@]' |
  xargs -I {} basename {} |
  gsed -e 's/.conda\|.tar.bz2//g' |
  sort -u) \
  >"${SNAPSHOT_DIR}/miniforge${SUFFIX}.txt"
code --list-extensions --show-versions | sort -d -f \
  >"${SNAPSHOT_DIR}/code${SUFFIX}.txt"
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
