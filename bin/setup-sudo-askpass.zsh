#!/usr/bin/env zsh
# =============================================================================
# setup-sudo-askpass.zsh — Store sudo password in Keychain and wire askpass
# =============================================================================
#
# Usage:
#   source setup-sudo-askpass.zsh
#
# Description:
#   Prompts for the sudo password, stores it in the macOS Keychain under
#   the "CLI sudo" service name, symlinks get-cli-sudo-pass.zsh into ~/bin,
#   and exports SUDO_ASKPASS so that subsequent sudo -A calls in the same
#   shell session pick it up automatically.
#
#   Must be sourced (not executed) so that the SUDO_ASKPASS export reaches
#   the calling shell.
#
# Dependencies:
#   security, git
# =============================================================================

# NOTE: setopt is intentionally omitted — this file is sourced, so any
# setopt would affect the parent shell's options permanently.

readonly pw_name='CLI sudo'
readonly pw_account="${USER}"

echo -n "Password: "
read -rs sudo_password
echo   # move to a new line after the silent read

# Replace any existing keychain entry so the stored password stays current.
if security find-generic-password -w -s "${pw_name}" -a "${pw_account}" \
  &>/dev/null; then
  security delete-generic-password -s "${pw_name}" -a "${pw_account}" \
    &>/dev/null
fi
security add-generic-password \
  -s "${pw_name}" -a "${pw_account}" -w "${sudo_password}"

readonly GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
mkdir -p "${HOME}/bin"
readonly SUDO_ASKPASS_SCRIPT='get-cli-sudo-pass.zsh'
ln -sf "${GIT_ROOT_DIR}/bin/${SUDO_ASKPASS_SCRIPT}" "${HOME}/bin"
export SUDO_ASKPASS="${HOME}/bin/${SUDO_ASKPASS_SCRIPT}"
