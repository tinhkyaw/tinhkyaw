#!/usr/bin/env zsh
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}" || exit
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
if [[ ! -d gitignore ]]; then
    git clone git@github.com:github/gitignore
fi
cd gitignore
git pull
PREFIX='https://github.com/github/gitignore/blob/main/'
if [[ -f ${GIT_ROOT_DIR}/.gitignore ]]; then
    rm ${GIT_ROOT_DIR}/.gitignore
fi
for template in $(cat ${GIT_ROOT_DIR}/packages/gitignore); do
    {
        echo "# $(basename -s .gitignore $template)"
        echo "# src: $PREFIX$template"
        echo "# ----------------------------------------------------------------------------"
        cat ${template}
        echo "\n"
    } >>${GIT_ROOT_DIR}/.gitignore
done
cd "${WD}" || exit
