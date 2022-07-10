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
ncu -g
pip3 install --upgrade pip setuptools
pip3 freeze --local | cut -d = -f 1 | cut -d ' ' -f 1 | xargs pip3 install --upgrade --use-deprecated=legacy-resolver
conda update --all
gcloud components update
apm upgrade
color=green
if [[ -d ~/.bash-my-aws ]]; then
  cd ~/.bash-my-aws
  print -P "%F{$color}Updating ~/.bash-my-aws%f"
  git pull
fi
if [[ -d ~/.emacs.d ]]; then
  cd ~/.emacs.d
  print -P "%F{$color}Updating spacemacs%f"
  git pull
fi
if [[ -d ~/.yadr ]]; then
  cd ~/.yadr
  print -P "%F{$color}Updating ~/.yadr%f"
  git pull
fi
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  print -P "%F{$color}Updating ~/.zprezto%f"
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
  zprezto-update
fi
update-gitignore.zsh
cd ${P}
