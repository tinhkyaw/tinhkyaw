#!/usr/bin/env bash
set -e
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  brew install coreutils
fi
CPATH=$(xcrun --show-sdk-path)/usr/include
export CPATH
export LDFLAGS="-L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib/system"
export SLUGIFY_USES_TEXT_UNIDECODE=yes
DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}"
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
xargs -I {} brew tap {} <"${GIT_ROOT_DIR}"/packages/taps
xargs brew install <"${GIT_ROOT_DIR}"/packages/brews
xargs brew install --cask <"${GIT_ROOT_DIR}"/packages/casks
# xargs npm install -g <"${GIT_ROOT_DIR}"/packages/npms
# apm install --packages-file "${GIT_ROOT_DIR}"/packages/atom_packages
# xargs -I {} code --install-extension {} <"${GIT_ROOT_DIR}"/packages/vscode_extensions
# pip3 install -U --use-deprecated=legacy-resolver -r "${GIT_ROOT_DIR}"/packages/pip3s
# git clone https://github.com/bash-my-aws/bash-my-aws.git ~/.bash-my-aws
# sh -c "`curl -fsSL https://raw.githubusercontent.com/skwp/dotfiles/master/install.sh `"
# sh -c "`curl -fsSL https://raw.githubusercontent.com/skwp/dotfiles/master/install.sh `"
# cd $ZPREZTODIR
# git clone --recurse-submodules https://github.com/belak/prezto-contrib contrib
"${GIT_ROOT_DIR}"/scripts/setup-bin.sh
"${GIT_ROOT_DIR}"/scripts/setup-conf.sh
