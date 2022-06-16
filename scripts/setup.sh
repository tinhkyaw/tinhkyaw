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
xargs npm install -g <"${GIT_ROOT_DIR}"/packages/npms
apm install --packages-file "${GIT_ROOT_DIR}"/packages/atom_packages
xargs -I {} code --install-extension {} <"${GIT_ROOT_DIR}"/packages/vscode_extensions
pip3 install -U -r "${GIT_ROOT_DIR}"/packages/pip3s
if [ ! -d "$ZSH" ]; then
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
  FONTS_DIR=~/.oh-my-zsh/custom/fonts
  git clone git@github.com:powerline/fonts ${FONTS_DIR}
  cd ${FONTS_DIR}
  ./install.sh
  git clone https://github.com/bash-my-aws/bash-my-aws.git ~/.bash-my-aws
  "${GIT_ROOT_DIR}"/scripts/setup-bin.sh
  "${GIT_ROOT_DIR}"/scripts/setup-conf.sh
  GREEN="$(tput setaf 2)"
  NORMAL="$(tput sgr0)"
  printf '%s'"${GREEN}"
  echo 'Please update color scheme in iTerm via iTerm2 → Preferences → Profiles → Colors → Color Presets → Solarized Dark'
  echo 'Also, please update font in iTerm via iTerm2 → Preferences → Profiles → Text → Change Font → Hack Nerd Font size 14'
  echo 'You may also want to update .gitconfig'
  printf '%s'"${NORMAL}"
  env zsh -l
fi
if [ -z "$ZSH" ]; then
  ZSH=~/.oh-my-zsh
fi
