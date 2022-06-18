#!/usr/bin/env bash
WD=$(pwd)
account="$(whoami)"
echo -n Password:
read -rs sudo_password
security add-generic-password -s 'CLI sudo' -a "${account}" -w "${sudo_password}"
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
# shellcheck disable=SC1091
source "${GIT_ROOT_DIR}"/scripts/setup-common.sh
mkdir -p "${HOME}"/bin
install_file get-cli-sudo-pass.sh "${GIT_ROOT_DIR}"/scripts "${HOME}"/bin
export SUDO_ASKPASS="${HOME}"/bin/get-cli-sudo-pass.sh
"${HOME}"/bin/get-cli-sudo-pass.sh
cd "${WD}" || exit
