#!/usr/bin/env bash
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "$0")")
cd ${DIR}
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
function install_file() {
  local file_name="${1}"
  local src_dir="${2}"
  local dst_dir="${3}"
  local src="${src_dir}/${file_name}"
  local dst="${dst_dir}/${file_name}"
  if [ -e ${dst} ]
  then
    if ! diff ${src} ${dst} &> /dev/null
    then
      mv ${dst} ${dst}.BAK
      ln -s ${src} ${dst_dir}/
    fi
  elif [ -L ${dst} ]
  then
    mv ${dst} ${dst}.BAK
    ln -s ${src} ${dst_dir}/
  else
    ln -s ${src} ${dst_dir}/
  fi  
}
function replace_file() {
  local file_name="${1}"
  local src_dir="${2}"
  local dst_dir="${3}"
  local src="${src_dir}/${file_name}"
  local dst="${dst_dir}/${file_name}"
  if [ -e ${dst} ]
  then
    if ! diff ${src} ${dst} &> /dev/null
    then
      mv ${dst} ${dst}.BAK
      cp ${src} ${dst_dir}/
    fi
  elif [ -L ${dst} ]
  then
    mv ${dst} ${dst}.BAK
    cp ${src} ${dst_dir}/
  else
    cp ${src} ${dst_dir}/    
  fi  
}
replace_file .gitconfig ${GIT_ROOT_DIR}/conf ${HOME}
for conf_file in .bashrc .bash_profile
do
  install_file ${conf_file} ${GIT_ROOT_DIR}/conf ${HOME}
done
mkdir -p ${HOME}/bin
for script_file in emacs cleanup-caskroom.sh git-pull-all.sh snapshot.sh update-all.sh
do
  install_file ${script_file} ${GIT_ROOT_DIR}/scripts ${HOME}/bin
done
for package_file in ignored slow
do
  install_file ${package_file} ${GIT_ROOT_DIR}/packages ${HOME}/bin
done
mkdir -p ${HOME}/.emacs.d
install_file init.el ${GIT_ROOT_DIR}/conf ${HOME}/.emacs.d
if ! diff ${GIT_ROOT_DIR}/conf/paths /etc/paths &> /dev/null
then
  sudo cp ${GIT_ROOT_DIR}/conf/paths /etc/
fi
cd ${WD}
