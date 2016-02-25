#!/usr/bin/env bash
DIR=$(dirname "$(type -a "$0" | cut -d ' ' -f 3)")
is_quick=false
while getopts q flag
do
  case ${flag} in
    q)
      is_quick=true
      ;;
    ?)
    exit 1
    ;;
  esac
done
shift $(( OPTIND - 1 ));
brew update
brew upgrade --all
brew upgrade cask
for package in $(brew cask list)
do
  ver=$(brew cask info ${package} | head -1 | cut -d ' ' -f 2)
  if [ $ver == 'latest' ]
  then
    if grep -Fxq ${package} "$(readlink ${DIR}/ignored)"
    then
      echo "Ignoring ${package}"
    else
      if ${is_quick} && grep -Fxq ${package} "$(readlink ${DIR}/slow)"
      then
        echo "Skipping ${package} update for speed"
      else
        echo "Reinstalling latest ${package}"
        brew cask install --force --download ${package}
      fi
    fi
  else
    brew cask install ${package}
  fi
done
brew cleanup --force
brew linkapps
brew cask cleanup
cleanup-caskroom.sh
brew doctor
gem update --system
gem update
gem cleanup
pip install --upgrade pip setuptools
pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs pip install --no-binary :all: --upgrade
