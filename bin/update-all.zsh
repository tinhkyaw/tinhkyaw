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
uv tool upgrade --all
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1
export CC=clang-omp CXX=clang-omp++
rustup update
"${HOMEBREW_PREFIX}"/anaconda3/bin/conda update \
  -p "${HOMEBREW_PREFIX}"/anaconda3 --all -y
conda update -n base --all -y
gcloud components update -q
doom env
doom -! sync
doom -! upgrade
color=blue
ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
if [[ -s "${ZIM_HOME}/init.zsh" ]]; then
  source "${ZIM_HOME}/init.zsh"
  zimfw upgrade -v
  zimfw update -v
fi
cd "${HOME}" || exit
mr -j5 update
update-gi.zsh
color=blue
print -P "%F{${color}}Updating cpan packages%f"
cpan-outdated --exclude-core | cpanm
print -P "%F{${color}}$(date)%f"
cd "${WD}" || exit
