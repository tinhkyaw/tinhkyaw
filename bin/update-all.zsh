#!/usr/bin/env zsh
WD=$(pwd)
brew missing
brew update
brew upgrade
brew cu -ay
brew cleanup -s
brew doctor
mas outdated
mas upgrade
gem update --system
gem update
gem cleanup
timeout --foreground 3m npm-check -g -y
"${HOMEBREW_PREFIX}"/bin/pip3 install --upgrade pip setuptools
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1
export CC=clang-omp CXX=clang-omp++
"${HOMEBREW_PREFIX}"/bin/pip3 freeze --local |
  cut -d = -f 1 |
  cut -d ' ' -f 1 |
  xargs "${HOMEBREW_PREFIX}"/bin/pip3 install \
  --upgrade --use-deprecated=legacy-resolver
rustup update
"${HOMEBREW_PREFIX}"/anaconda3/bin/conda update \
  -p "${HOMEBREW_PREFIX}"/anaconda3 --all -y
conda update -n base --all -y
gcloud components update -q
# apm upgrade
color=green
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  print -P "%F{${color}}Updating ${HOME}/.zprezto%f"
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
  zprezto-update
fi
cd "${HOME}" || exit
mr update
update-gi.zsh
color=green
print -P "%F{${color}}Updating cpan packages%f"
cpan-outdated --exclude-core | cpanm
cd "${WD}" || exit
