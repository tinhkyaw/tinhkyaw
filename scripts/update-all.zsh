#!/usr/bin/env zsh
P=$(pwd)
DIR=$(dirname $(type -a "${0}" | cut -d " " -f 3))
is_greedy=false
while getopts g flag; do
  case ${flag} in
  g)
    is_greedy=true
    ;;
  ?)
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))
brew missing
brew update
brew upgrade
brew outdated --cask
if ($is_greedy); then
  brew upgrade --cask --greedy
else
  brew cu -a
fi
brew cleanup -s
brew doctor
mas outdated
mas upgrade
gem update --system
gem update
gem cleanup
npm-check -u -g
npm-check-updates -g --timeout 150000
pip3 install --upgrade pip setuptools
pip3 freeze --local | cut -d = -f 1 | cut -d ' ' -f 1 | xargs pip3 install --upgrade --use-deprecated=legacy-resolver
conda update --all
gcloud components update
apm upgrade
color=green
if [[ -d ~/.emacs.d ]]; then
  cd ~/.emacs.d
  print -P "%F{$color}Updating spacemacs%f"
  git pull
fi
if [[ -d ~/.bash-my-aws ]]; then
  cd ~/.bash-my-aws
  print -P "%F{$color}Updating ~/.bash-my-aws%f"
  git pull
fi
if [[ -d ~/.yadr ]]; then
  cd ~/.yadr
  print -P "%F{$color}Updating ~/.yadr%f"
  git pull
fi
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  color=green
  print -P "%F{$color}Updating ~/.zprezto%f"
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
  zprezto-update
fi
cd ${P}
