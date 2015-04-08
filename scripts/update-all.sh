#!/usr/bin/env bash
brew update;
brew upgrade;
brew upgrade brew-cask;
for cask in $(brew cask list);
do
    ver=$(brew cask info $cask | head -1 | cut -d ' ' -f 2);
    if [ $ver == 'latest' ];
    then
        echo reinstalling $ver $cask;
#        brew cask install $cask --force --download;
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
