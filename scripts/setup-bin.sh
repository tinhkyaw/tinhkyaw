#!/usr/bin/env bash
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "$0")")
cd ${DIR}
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
source ${GIT_ROOT_DIR}/scripts/common.sh
mkdir -p ${HOME}/bin
for script_file in emacs cleanup-caskroom.sh git-pull-all.sh snapshot.sh update-all.sh
do
  install_file ${script_file} ${GIT_ROOT_DIR}/scripts ${HOME}/bin
done
for package_file in ignored slow
do
  install_file ${package_file} ${GIT_ROOT_DIR}/packages ${HOME}/bin
done
cd ${WD}
