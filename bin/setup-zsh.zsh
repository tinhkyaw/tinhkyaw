#!/usr/bin/env zsh
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}" || exit
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
cd "${WD}" || exit
cp "${GIT_ROOT_DIR}/conf/ssh_config" "${HOME}/.ssh/config"
if [[ -d "${HOME}/.bash-my-aws" ]]; then
  rm -rf "${HOME}/.bash-my-aws"
fi
git clone https://github.com/bash-my-aws/bash-my-aws.git \
  "${BMA_HOME:-$HOME/.bash-my-aws}"
mr register "${HOME}/.bash-my-aws"
sh -c \
  "$(
    curl -fsSL https://raw.githubusercontent.com/skwp/dotfiles/master/install.sh
  )"
mr register "${HOME}/.yadr"
if [[ -d "${ZDOTDIR:-$HOME}/.zprezto" ]]; then
  rm -rf "${ZDOTDIR:-$HOME}/.zprezto"
fi
git clone --recursive \
  https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -sf "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done
cd "${ZDOTDIR:-$HOME}/.zprezto"
if [[ -d contrib ]]; then
  rm -rf contrib
fi
git clone --recurse-submodules https://github.com/belak/prezto-contrib \
  contrib
for rcfile in "${GIT_ROOT_DIR}"/conf/zsh/*; do
  ln -sf "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done
(cd "${ZDOTDIR:-$HOME}/.zprezto/modules/history-substring-search/external" &&
  git checkout master)
COMPLETION_DOCKER='https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker'
curl -sSL "${COMPLETION_DOCKER}" \
  >"${ZDOTDIR:-$HOME}/.zprezto/modules/completion/external/src/_docker"
mkdir -p "$HOME/.config/git/"
ln -sf "${GIT_ROOT_DIR}/conf/git/gitattributes" "${HOME}/.config/git/attributes"
ln -sf "${GIT_ROOT_DIR}/conf/git/gitconfig" "${ZDOTDIR:-$HOME}/.gitconfig"
echo "function gi()
  { curl -sLw "\n" https://www.toptal.com/developers/gitignore/api/$@ ;}" \
  >>"${HOME}"/.zshrc
ln -sf "${GIT_ROOT_DIR}/.gitignore" "${ZDOTDIR:-$HOME}/.gitignore"
if [[ -f "${HOME}"/.inputrc ]]; then
  unlink "${HOME}"/.inputrc
fi
if [[ -d "${HOME}"/.emacs.d ]]; then
  mv "${HOME}"/.emacs.d "${HOME}"/.emacs.d.BAK
fi
if [[ -f "${HOME}"/.emacs ]]; then
  mv "${HOME}"/.emacs "${HOME}"/.emacs.BAK
fi
git clone https://github.com/syl20bnr/spacemacs "${HOME}"/.emacs.d
mr register "${HOME}/.emacs.d"
if [[ -f "${HOME}"/.spacemacs ]]; then
  mv "${HOME}"/.spacemacs "${HOME}"/.spacemacs.BAK
fi
for conf_file in \
  condarc \
  spacemacs; do
  ln -sf "${GIT_ROOT_DIR}/conf/${conf_file}" "${HOME}/.${conf_file}"
done
mkdir -p "$HOME/.ssh"
ln -sf "${GIT_ROOT_DIR}/conf/settings.json" \
  "${HOME}/Library/Application Support/Code/User/settings.json"
for script_file in \
  diff-snap.zsh \
  s3cat \
  snapshot.zsh \
  tunnel \
  update-all.zsh \
  update-gi.zsh; do
  ln -sf "${GIT_ROOT_DIR}/bin/${script_file}" \
  "${HOME}/bin"
done
cd "${WD}" || exit
