#!/usr/bin/env bash
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}" || exit
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1091
source "${GIT_ROOT_DIR}"/bin/setup-common.sh
mkdir -p "${HOME}"/bin
for script_file in \
  diff-snap.zsh \
  s3cat \
  snapshot.zsh \
  tunnel \
  update-all.zsh \
  update-gi.zsh; do
  install_file "${script_file}" "${GIT_ROOT_DIR}"/bin "${HOME}"/bin
done
cd "${WD}" || exit
