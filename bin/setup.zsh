#!/usr/bin/env zsh
set -e
if ! command -v brew &>/dev/null; then
  /bin/bash -c \
    "$(
      curl -fsSL \
        https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
    )"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  brew install coreutils git mr
  ln -s "$(brew --prefix)" "${HOME}"/.brew
fi
DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}"
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
LIST_DIR="${GIT_ROOT_DIR}/lists"
"${GIT_ROOT_DIR}"/bin/setup-zsh.zsh
CPATH=$(xcrun --show-sdk-path)/usr/include
export CPATH
CLI_PATH='/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib/system'
export LDFLAGS="-L${CLI_PATH}"
export SLUGIFY_USES_TEXT_UNIDECODE=yes
xargs -I {} brew tap {} <"${LIST_DIR}"/taps.txt
xargs brew install <"${LIST_DIR}"/brews.txt
rustup-init -y
source "${GIT_ROOT_DIR}"/bin/setup-sudo-askpass.zsh
if [[ $(spctl --status) =~ "assessments enabled" ]]; then
  sudo spctl --master-disable
fi
xargs -I {} brew install --cask {} <"${LIST_DIR}"/casks.txt
conda init "$(basename "${SHELL}")"
xargs npm install -g <"${LIST_DIR}"/npms.txt
xargs -I {} code --install-extension {} <"${LIST_DIR}"/codes.txt
pip3 install -U --use-deprecated=legacy-resolver -r "${LIST_DIR}"/pip3s.txt
xargs gem install <"${LIST_DIR}"/gems.txt
defaults write com.apple.versioner.perl Version -string 5.18 # for csshX
PERL_SETUP='setup-perl.zsh'
ln -sf "${GIT_ROOT_DIR}/bin/${PERL_SETUP}" "${HOME}/bin/${PERL_SETUP}"
"${GIT_ROOT_DIR}/bin/${PERL_SETUP}"
