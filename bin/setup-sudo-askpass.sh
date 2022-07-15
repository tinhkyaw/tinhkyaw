#!/usr/bin/env bash
WD=$(pwd)
pw_name='CLI sudo'
account="${USER}"
echo -n Password:
read -rs sudo_password
if security find-generic-password -w -s "${pw_name}" -a "${account}" \
  &>/dev/null; then
  security delete-generic-password -s "${pw_name}" -a "${account}" \
    &>/dev/null
fi
security add-generic-password -s 'CLI sudo' \
  -a "${account}" -w "${sudo_password}"
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
mkdir -p "$HOME/bin"
ln -sf "${GIT_ROOT_DIR}/bin/get-cli-sudo-pass.sh" "${HOME}/bin"
export SUDO_ASKPASS="${HOME}/bin/get-cli-sudo-pass.sh"
"${HOME}"/bin/get-cli-sudo-pass.sh
cd "${WD}" || exit
