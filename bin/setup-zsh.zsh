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
fi
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
mkdir -p "${HOME}/.config/git/"
ln -sf "${GIT_ROOT_DIR}/conf/git/gitattributes" \
  "${HOME}/.config/git/attributes"
cp "${GIT_ROOT_DIR}/conf/git/gitconfig.user" "${HOME}/.gitconfig.user"
ln -sf "${GIT_ROOT_DIR}/.gitignore" "${HOME}/.gitignore"
if [[ -f "${HOME}"/.inputrc ]]; then
  unlink "${HOME}"/.inputrc
fi
for conf_file in \
  condarc \
  prettierrc \
  git/gitconfig \
  zsh/zimrc \
  zsh/zshrc; do
  ln -sf "${GIT_ROOT_DIR}/conf/${conf_file}" "${HOME}/.$(basename ${conf_file})"
done
for vscode_ide in Code Antigravity Cursor; do
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
