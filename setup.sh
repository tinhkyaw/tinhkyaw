#!/usr/bin/env bash
if ! command -v brew &> /dev/null
then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  brew install git coreutils python ruby
fi
DIR=$(dirname "$(greadlink -f "$0")")
if ! brew list emacs &> /dev/null
then
  brew install --with-cocoa --with-glib --with-gnutls --with-imagemagick --with-librsvg --with-mailutils emacs
fi
if ! brew list gnuplot &> /dev/null
then
  brew install --with-aquaterm --with-cairo --with-latex --with-qt --with-wxmac gnuplot
fi
if ! brew list octave &> /dev/null
then
  brew install --with-audio --with-gui octave
fi
if ! brew list cask &> /dev/null
then
  brew install cask
  cat ${DIR}/conf/casks | xargs brew cask install
fi
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
for conf_file in .bashrc .bash_profile .gitconfig
do
  install_file ${conf_file} ${DIR}/conf ${HOME}
done
mkdir -p ${HOME}/bin
for scr in cleanup-caskroom.sh emacs ignored update-all.sh
do
  install_file ${scr} ${DIR}/scripts ${HOME}/bin
done
mkdir -p ${HOME}/.emacs.d
install_file init.el ${DIR}/scripts ${HOME}/.emacs.d
if ! diff ${DIR}/conf/paths /etc/paths &> /dev/null
then
  sudo cp ${DIR}/conf/paths /etc/
fi
