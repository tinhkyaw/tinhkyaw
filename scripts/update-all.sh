#!/usr/bin/env bash
DIR=$(dirname "$(greadlink -f "$0")")
brew update;
brew upgrade --all;
brew upgrade brew-cask;
for cask in $(brew cask list);
do
    ver=$(brew cask info $cask | head -1 | cut -d ' ' -f 2);
    if [ $ver == 'latest' ];
    then
        if grep -Fxq $cask $DIR/ignored
        then
            echo Ignoring $cask
        else
            echo Reinstalling latest $cask
            brew cask install $cask --force --download;
        fi
    else
        brew cask install $cask;
    fi;
done
brew cleanup --force;
brew cask cleanup;
brew doctor;
gem update --system;
gem update;
gem cleanup;
pip install --upgrade pip setuptools;
pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs pip install --no-use-wheel --upgrade;
