#!/usr/bin/env zsh
# =============================================================================
# get-cli-sudo-pass.zsh — Retrieve the sudo password from the macOS Keychain
# =============================================================================
#
# Usage:
#   get-cli-sudo-pass.zsh
#
# Description:
#   Fetches the password stored under the "CLI sudo" Keychain entry by
#   setup-sudo-askpass.zsh and prints it to stdout. Intended to be used
#   as the SUDO_ASKPASS helper: sudo -A will invoke this script instead of
#   prompting interactively.
#
# Dependencies:
#   security  — pre-installed on macOS
# =============================================================================

setopt ERR_EXIT PIPE_FAIL NO_UNSET

readonly pw_name='CLI sudo'
readonly pw_account="${USER}"

if ! cli_sudo_pass=$(
  security find-generic-password -w -s "${pw_name}" -a "${pw_account}" \
    2>/dev/null
); then
  echo "Error: '${pw_name}' password not found in Keychain" \
       "for '${pw_account}'" >&2
  echo "Run setup-sudo-askpass.zsh to store it." >&2
  exit 1
fi

echo "${cli_sudo_pass}"
