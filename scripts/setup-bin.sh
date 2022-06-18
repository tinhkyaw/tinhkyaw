#!/usr/bin/env bash
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}" || exit
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_ROOT_DIR}"/scripts/setup-common.sh
mkdir -p "${HOME}"/bin
for script_file in emacs diff-snap.zsh cleanup-caskroom.zsh find-broken-casks.sh git-pull-all.zsh snapshot.zsh s3cat tunnel update-all.zsh; do
  install_file "${script_file}" "${GIT_ROOT_DIR}"/scripts "${HOME}"/bin
done
cd "${WD}" || exit
