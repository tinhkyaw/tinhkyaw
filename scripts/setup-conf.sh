#!/usr/bin/env bash
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "$0")")
cd ${DIR}
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
source ${GIT_ROOT_DIR}/scripts/setup-common.sh
replace_file .gitconfig ${GIT_ROOT_DIR}/conf ${HOME}
for conf_file in .zshrc
do
  install_file ${conf_file} ${GIT_ROOT_DIR}/conf ${HOME}
done
mkdir -p ${HOME}/.emacs.d
install_file init.el ${GIT_ROOT_DIR}/conf ${HOME}/.emacs.d
mkdir -p ${HOME}/.ssh
cp ssh_config ${HOME}/.ssh/config
cd ${WD}
