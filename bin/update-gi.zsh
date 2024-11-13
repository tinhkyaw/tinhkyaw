#!/usr/bin/env zsh
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}" || exit
color=blue
print -P "%F{${color}}Updating gitignore%f"
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
template_list=$(awk -vORS=, '{ print $1 }' \
  "${GIT_ROOT_DIR}"/lists/gis.txt |
  gsed -e 's/,$/\n/g')
curl -sLw "\n" \
  https://www.toptal.com/developers/gitignore/api/"${template_list}" |
  gsed -e \
    's/^bin/# &/;
    s/^bin\//# &/;
    s/\[Bb\]in/# &/;
    s/*\/Makefile/# &/;
    s/\/public/**&/;' \
    >"${GIT_ROOT_DIR}"/.gitignore
echo '**/.genaiscript/**' >>"${GIT_ROOT_DIR}"/.gitignore
cd "${WD}" || exit
