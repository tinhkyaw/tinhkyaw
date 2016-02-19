#!/usr/bin/env bash
DIR=$(dirname "$(greadlink -f "$0")")
rm ~/.bashrc ~/.bash_profile ~/.gitconfig
ln -s ${DIR}/conf/.bashrc ~/
ln -s ${DIR}/conf/.bash_profile ~/
ln -s ${DIR}/conf/.gitconfig ~/
sudo cp conf/paths /etc/
rm -r ~/.emacs.d
mkdir -p ~/.emacs.d
ln -s ${DIR}/scripts/init.el ~/.emacs.d/
rm -r ~/bin
mkdir -p ~/bin
ln -s ${DIR}/scripts/cleanup-caskroom.sh ~/bin/
ln -s ${DIR}/scripts/emacs ~/bin/
ln -s ${DIR}/scripts/ignored ~/bin/
ln -s ${DIR}/scripts/update-all.sh ~/bin/
