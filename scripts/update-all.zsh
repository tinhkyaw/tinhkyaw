#!/usr/bin/env zsh
DIR=$(dirname $(type -a "${0}" | cut -d " " -f 3))
is_greedy=false
while getopts g flag
do
  case ${flag} in
    g)
      is_greedy=true
      ;;
    ?)
    exit 1
    ;;
  esac
done
shift $(( OPTIND - 1 ))
brew update
brew upgrade
if ( $is_greedy )
then
  brew cask upgrade --greedy
else
  brew cu -a
fi
brew cleanup -s
brew doctor
gem update --system
gem update
gem cleanup
npm update -f -g
npm-check -u -g
npm-check-updates -g
pip3 install --upgrade pip setuptools
pip3 freeze --local | cut -d = -f 1 | xargs pip3 install --upgrade
conda update --all
poetry self update
apm upgrade
env ZSH=$ZSH sh $ZSH/tools/upgrade.sh
gcloud components update
