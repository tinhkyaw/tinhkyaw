#!/usr/bin/env zsh
P=$(pwd)
brew missing
brew update
brew upgrade
brew outdated --cask
brew cu -ay
brew cleanup -s
brew doctor
mas outdated
mas upgrade
gem update --system
gem update
gem cleanup
npm-check -g -y
pip3 install --upgrade pip setuptools
pip3 freeze --local |
  cut -d = -f 1 |
  cut -d ' ' -f 1 |
  xargs pip3 install --upgrade --use-deprecated=legacy-resolver
rustup update
conda update --all -y
gcloud components update -q
apm upgrade
color=green
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  print -P "%F{$color}Updating ~/.zprezto%f"
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
  zprezto-update
fi
mr update
update-gi.zsh
cd ${P}
