#!/usr/bin/env zsh
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}" || exit
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
cd "${WD}" || exit
if [[ -d $HOME/.bash-my-aws ]]; then
  rm -rf $HOME/.bash-my-aws
fi
git clone https://github.com/bash-my-aws/bash-my-aws.git ${BMA_HOME:-$HOME/.bash-my-aws}
sh -c "$(curl -fsSL https://raw.githubusercontent.com/skwp/dotfiles/master/install.sh)"
if [[ -d ${ZDOTDIR:-$HOME}/.zprezto ]]; then
  rm -rf ${ZDOTDIR:-$HOME}/.zprezto
fi
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -sf "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done
cd "${ZDOTDIR:-$HOME}/.zprezto"
if [[ -d contrib ]]; then
  rm -rf contrib
fi
git clone --recurse-submodules https://github.com/belak/prezto-contrib contrib
for rcfile in "${GIT_ROOT_DIR}"/conf/zsh/*; do
  ln -sf "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done
ln -sf "${GIT_ROOT_DIR}/conf/.gitignore" "${ZDOTDIR:-$HOME}/.gitignore"
cd "${WD}" || exit
