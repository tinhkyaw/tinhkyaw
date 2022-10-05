#!/usr/bin/env zsh
pw_name="CLI sudo"
pw_account="${USER}"
if ! cli_sudo_pass=$(
  security find-generic-password -w -s "${pw_name}" -a "${pw_account}"
); then
  echo "error $?"
  exit 1
fi
echo "${cli_sudo_pass}"
