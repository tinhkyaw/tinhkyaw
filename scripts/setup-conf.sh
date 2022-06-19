#!/usr/bin/env bash
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}" || exit
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1091
source "${GIT_ROOT_DIR}"/scripts/setup-common.sh
mkdir -p "${HOME}"/.ssh
cp "${GIT_ROOT_DIR}"/conf/ssh_config "${HOME}"/.ssh/config
install_file settings.json "${GIT_ROOT_DIR}"/conf "${HOME}"/Library/Application\ Support/Code/User
cd "${WD}" || exit
