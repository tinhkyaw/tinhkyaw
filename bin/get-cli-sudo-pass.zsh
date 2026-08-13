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
#   security, dscl  — pre-installed on macOS
# =============================================================================

setopt ERR_EXIT PIPE_FAIL NO_UNSET

readonly pw_name='CLI sudo'
readonly pw_account="${USER}"

# Resolve the account's home directory via Directory Services rather than
# trusting $HOME: callers like Homebrew Cask's sandboxed artifact steps
# exec `sudo` with a fake $HOME still set in the environment (the sandbox
# jail is lifted for `sudo` itself, but inherited env vars are not reset),
# which otherwise points the default keychain search list at a directory
# that was never used to store this password.
real_home=$(dscl . -read "/Users/${pw_account}" NFSHomeDirectory \
  2>/dev/null | awk '{print $NF}')
readonly real_home
readonly login_keychain="${real_home}/Library/Keychains/login.keychain-db"

if ! cli_sudo_pass=$(
  security find-generic-password -w -s "${pw_name}" -a "${pw_account}" \
    "${login_keychain}" 2>/dev/null
); then
  echo "Error: '${pw_name}' password not found in Keychain" \
       "for '${pw_account}'" >&2
  echo "Run setup-sudo-askpass.zsh to store it." >&2
  exit 1
fi

echo "${cli_sudo_pass}"
