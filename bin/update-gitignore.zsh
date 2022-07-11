#!/usr/bin/env zsh
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}" || exit
color=green
print -P "%F{$color}Updating gitignore%f"
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
if [[ ! -d gitignore ]]; then
    git clone git@github.com:github/gitignore
fi
cd gitignore
git pull
PREFIX='https://github.com/github/gitignore/blob/main/'
read -r -d '' GITIGNORE_EXTRAS <<EOF
.bsp
.fake
.idea
.vscode
EOF
if [[ -f ${GIT_ROOT_DIR}/.gitignore ]]; then
    rm ${GIT_ROOT_DIR}/.gitignore
fi
for template in $(cat ${GIT_ROOT_DIR}/lists/ghgis.txt); do
    {
        echo "# $(basename -s .gitignore $template)"
        echo "# src: $PREFIX$template"
        echo "# ----------------------------------------------------------------------------"
        cat ${template}
        echo "\n"
    } >>${GIT_ROOT_DIR}/.gitignore
done
echo ${GITIGNORE_EXTRAS} >>${GIT_ROOT_DIR}/.gitignore
cd "${WD}" || exit
