#!/usr/bin/env zsh
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}" || exit
color=green
print -P "%F{${color}}Updating gitignore%f"
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
template_list=$(awk -vORS=, '{ print $1 }' \
  ${GIT_ROOT_DIR}/lists/gis.txt |
  sed 's/,$/\n/g')
curl -sLw "\n" \
  https://www.toptal.com/developers/gitignore/api/${template_list} |
  sed \
    's/bin\//# &/;
    s/\[Bb\]in/# &/;
    s/*\/Makefile/# &/;' \
    >${GIT_ROOT_DIR}/.gitignore
cd "${WD}" || exit