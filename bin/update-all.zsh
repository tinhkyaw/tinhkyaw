#!/usr/bin/env zsh
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}" || exit
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
LIST_DIR="${GIT_ROOT_DIR}/lists"
brew missing
brew update
brew upgrade
brew cu -ay
brew cleanup -s
brew doctor
/usr/sbin/softwareupdate -ia
mas outdated
mas upgrade
gem update --system
gem update
gem cleanup
timeout --foreground 3m npm-check -g -y
python3 -m pip install --upgrade pip
# "${HOMEBREW_PREFIX}"/bin/pip3 install --upgrade --break-system-packages setuptools
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1
export CC=clang-omp CXX=clang-omp++
pip3 install \
  --upgrade \
  --use-deprecated=legacy-resolver \
  --break-system-packages \
  -r "${LIST_DIR}"/pip3s.txt
rustup update
"${HOMEBREW_PREFIX}"/anaconda3/bin/conda update \
  -p "${HOMEBREW_PREFIX}"/anaconda3 --all -y
conda update -n base --all -y
gcloud components update -q
doom env
doom -! sync
doom -! upgrade
color=blue
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  print -P "%F{${color}}Updating ${HOME}/.zprezto%f"
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
  zprezto-update
fi
cd "${HOME}" || exit
mr -j5 update
update-gi.zsh
color=blue
print -P "%F{${color}}Updating cpan packages%f"
cpan-outdated --exclude-core | cpanm
print -P "%F{${color}}$(date)%f"
cd "${WD}" || exit
