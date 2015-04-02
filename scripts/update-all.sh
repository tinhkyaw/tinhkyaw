#!/usr/bin/env bash
brew update;
brew upgrade;
brew upgrade brew-cask;
brew cleanup --force;
brew cask cleanup;
brew doctor;
gem update --system;
gem update;
gem cleanup;
pip install --upgrade pip setuptools;
pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs pip install --no-use-wheel --upgrade;
