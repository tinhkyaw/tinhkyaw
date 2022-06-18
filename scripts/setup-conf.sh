#!/usr/bin/env bash
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}" || exit
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
# shellcheck source=./setup-common.sh
source "${GIT_ROOT_DIR}"/scripts/setup-common.sh
for conf_file in .gitconfig .zshrc; do
  replace_file "${conf_file}" "${GIT_ROOT_DIR}"/conf "${HOME}"
done
mkdir -p "${HOME}"/.emacs.d
install_file init.el "${GIT_ROOT_DIR}"/conf "${HOME}"/.emacs.d
mkdir -p "${HOME}"/.ssh
cp "${GIT_ROOT_DIR}"/conf/ssh_config "${HOME}"/.ssh/config
install_file settings.json "${GIT_ROOT_DIR}"/conf "${HOME}"/Library/Application\ Support/Code/User
cd "${WD}" || exit
