#!/usr/bin/env bash
brew list --cask 2>/dev/null | xargs -I{} bash -c 'cask_="{}"; brew audit --cask "${cask_}" 2>&1 1>/dev/null | grep "Hbc::DSL#license" >/dev/null && echo "License error in cask: ${cask_}"'
