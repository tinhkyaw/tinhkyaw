#!/usr/bin/env bash
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "$0")")
cd ${DIR}
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
source ${GIT_ROOT_DIR}/scripts/setup-common.sh
replace_file .gitconfig ${GIT_ROOT_DIR}/conf ${HOME}
for conf_file in .bashrc .bash_profile
do
  install_file ${conf_file} ${GIT_ROOT_DIR}/conf ${HOME}
done
mkdir -p ${HOME}/.emacs.d
install_file init.el ${GIT_ROOT_DIR}/conf ${HOME}/.emacs.d
if ! diff ${GIT_ROOT_DIR}/conf/paths /etc/paths &> /dev/null
then
  sudo cp ${GIT_ROOT_DIR}/conf/paths /etc/
fi
cd ${WD}
