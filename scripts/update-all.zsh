#!/usr/bin/env zsh
P=$(pwd)
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
brew missing
brew update
brew upgrade
brew outdated --cask
if ( $is_greedy )
then
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
npm-check-updates -g
pip3 install --upgrade pip setuptools
pip3 freeze --local | cut -d = -f 1 | xargs pip3 install --upgrade --use-deprecated=legacy-resolver
conda update --all
poetry self update
GIT_DIR=$(dirname "$(greadlink -f "${0}")")
cd ${GIT_DIR}
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
cd ${GIT_ROOT_DIR}
if ( $is_greedy )
then
  cat pyproject.toml| cut -d '=' -f 1 | egrep -v '^\[|name|version|description|authors|requires|build-backend|^$' | xargs poetry remove
  xargs < packages/poetry_packages poetry add
else
  poetry update
fi
apm upgrade
${HOME}/.oh-my-zsh/tools/upgrade.sh
gcloud components update
cd ${P}
