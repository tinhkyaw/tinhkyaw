#!/usr/bin/env zsh
if (( !${+commands[brew]} )); then
  /bin/bash -c \
    "$(
      curl -fsSL \
        https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
    )"
  sudo spctl --global-disable
  brew developer on
  brew install coreutils fd git grep mr ripgrep
  xargs -I {} brew tap {} <taps.txt
  brew install railwaycat/emacsmacport/emacs-mac \
    --with-modules --with-native-compilation
  ln -s "$(brew --prefix)" "${HOME}"/.brew
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}" || exit
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
LIST_DIR="${GIT_ROOT_DIR}/lists"
"${GIT_ROOT_DIR}"/bin/setup-zsh.zsh
CPATH=$(xcrun --show-sdk-path)/usr/include
export CPATH
CLI_PATH='/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib/system'
export LDFLAGS="-L${CLI_PATH}"
export SLUGIFY_USES_TEXT_UNIDECODE=yes
xargs brew install <"${LIST_DIR}"/brews.txt
rustup-init -y
if [[ ! -d "${HOME}/.config/emacs" ]]; then
  git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
  ~/.config/emacs/bin/doom install
  if [[ -d "${HOME}/.config/doom/config.el" ]]; then
    mv "${HOME}/.config/doom/config.el" "${HOME}/.config/doom/config.el.BAK"
  fi
  ln -sf "${GIT_ROOT_DIR}/conf/doom/config.el" "${HOME}/.config/doom/config.el"
fi
source "${GIT_ROOT_DIR}"/bin/setup-sudo-askpass.zsh
brew install --cask temurin
xargs -I {} brew install --cask {} <"${LIST_DIR}"/casks.txt
conda init "$(basename "${SHELL}")"
xargs npm install -g <"${LIST_DIR}"/npms.txt
for code_cmd in code cursor; do
  xargs -I {} "${code_cmd}" --install-extension {} <"${LIST_DIR}"/codes.txt
done
ln -sf "${GIT_ROOT_DIR}/conf/code/settings.json" \
  "${HOME}/Library/Application Support/Windsurf/User/settings.json"
ln -sf "${GIT_ROOT_DIR}/conf/zed/settings.json" \
  "${HOME}/.config/zed/settings.json"
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1
ln -s "${HOMEBREW_PREFIX}"/opt/llvm/bin/clang "${HOMEBREW_PREFIX}"/bin/clang-omp
ln -s "${HOMEBREW_PREFIX}"/opt/llvm/bin/clang++ "${HOMEBREW_PREFIX}"/bin/clang-omp++
export CC=clang-omp CXX=clang-omp++
xargs -I {} uv tool install {} <"${LIST_DIR}"/uvtools.txt
xargs gem install <"${LIST_DIR}"/gems.txt
defaults write com.apple.versioner.perl Version -string 5.18 # for csshX
PERL_SETUP='setup-perl.zsh'
ln -sf "${GIT_ROOT_DIR}/bin/${PERL_SETUP}" "${HOME}/bin/${PERL_SETUP}"
"${GIT_ROOT_DIR}/bin/${PERL_SETUP}"
