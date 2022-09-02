#!/usr/bin/env bash
set -e
if ! command -v brew &>/dev/null; then
  /bin/bash -c \
    "$(
      curl -fsSL
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
"${GIT_ROOT_DIR}"/bin/setup-zsh.sh
CPATH=$(xcrun --show-sdk-path)/usr/include
export CPATH
export LDFLAGS="-L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib/system"
export SLUGIFY_USES_TEXT_UNIDECODE=yes
xargs -I {} brew tap {} <"${LIST_DIR}"/taps.txt
xargs brew install <"${LIST_DIR}"/brews.txt
rustup-init -y
SUDO_ASKPASS="$(
  script="$(mktemp).scpt"

  echo '#!/usr/bin/osascript
    return text returned of (display dialog "Enter sudo Password:" with title "Administrator password needed" default answer "" buttons {"Cancel", "OK"} default button "OK" with hidden answer)
  ' >"${script}"

  chmod 500 "${script}"
  echo "${script}"
)"
export SUDO_ASKPASS
# shellcheck disable=SC1091
source "${GIT_ROOT_DIR}"/conf/zsh/zshrc
sudo spctl --master-disable
xargs brew install --cask <"${LIST_DIR}"/casks.txt
conda init "$(basename "${SHELL}")"
xargs npm install -g <"${LIST_DIR}"/npms.txt
xargs -I {} code --install-extension {} <"${LIST_DIR}"/codes.txt
pip3 install -U --use-deprecated=legacy-resolver -r "${LIST_DIR}"/pip3s.txt
xargs gem install <"${LIST_DIR}"/npms.txt
defaults write com.apple.versioner.perl Version -string 5.18 # for csshX
curl -L https://cpanmin.us |
  "${HOMEBREW_PREFIX}"/opt/perl/bin/perl - App::cpanminus
"${HOMEBREW_PREFIX}"/opt/perl/bin/cpanm \
  App::cpanoutdated File::HomeDir \
  Log::Log4perl \
  Term::ReadLine::Perl
md=$(perl -V | grep "^[ ]*${HOMEBREW_PREFIX}/lib/perl5/site_perl/" | sed 's/ //g')
if [[ ! -d "${md}" ]]; then
  print -P "%F{yellow}Warning:%f Creating the missing dir: ${md}"
  mkdir -p "$md"
  touch "$md/.gitignore"
fi
"${GIT_ROOT_DIR}"/bin/setup-sudo-askpass.sh
