#!/usr/bin/env zsh
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}" || exit
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
cd "${WD}" || exit
mkdir -p "${HOME}/.ssh"
cp "${GIT_ROOT_DIR}/conf/ssh_config" "${HOME}/.ssh/config"
GHUC='https://raw.githubusercontent.com'
if [[ ! -d "${HOME}/.yadr" ]]; then
  sh -c \
    "$(
      curl -fsSL \
      ${GHUC}/skwp/dotfiles/master/install.sh
    )"
  gsed -i 's/egrep -q/grep -Eq/' "${HOME}/.yadr/zsh/0_path.zsh"
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
  (cd "${ZDOTDIR:-$HOME}/.zprezto/modules/history-substring-search/external" \
  && git checkout master)
fi
mkdir -p "${HOME}/.config/git/"
ln -sf "${GIT_ROOT_DIR}/conf/git/gitattributes" \
  "${HOME}/.config/git/attributes"
ln -sf "${GIT_ROOT_DIR}/conf/git/gitconfig" "${HOME}/.gitconfig"
cp "${GIT_ROOT_DIR}/conf/git/gitconfig.user" "${HOME}/.gitconfig.user"
ln -sf "${GIT_ROOT_DIR}/.gitignore" "${HOME}/.gitignore"
if [[ -f "${HOME}"/.inputrc ]]; then
  unlink "${HOME}"/.inputrc
fi
for conf_file in \
  condarc; do
  ln -sf "${GIT_ROOT_DIR}/conf/${conf_file}" "${HOME}/.${conf_file}"
done
for vscode_ide in Code Cursor; do
  mkdir -p "${HOME}/Library/Application Support/${vscode_ide}/User/"
  ln -sf "${GIT_ROOT_DIR}/conf/code/settings.json" \
    "${HOME}/Library/Application Support/${vscode_ide}/User/settings.json"
done
mkdir -p "${HOME}/bin"
for script_file in \
  diff-snap.zsh \
  s3cat \
  snapshot.zsh \
  tunnel \
  update-all.zsh \
  update-gi.zsh; do
  ln -sf "${GIT_ROOT_DIR}/bin/${script_file}" \
  "${HOME}/bin/"
done
cd "${WD}" || exit
