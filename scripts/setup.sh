#!/usr/bin/env bash
set -e
if ! command -v brew &> /dev/null
then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi
brew install coreutils git mas openjdk python ruby swig
export SLUGIFY_USES_TEXT_UNIDECODE=yes
pip3 install -U virtualenvwrapper
DIR=$(dirname "$(greadlink -f "${0}")")
cd ${DIR}
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
if ! brew list node &> /dev/null
then
  brew install node
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  cat ${GIT_ROOT_DIR}/packages/npms | xargs npm install -g
fi
brew tap buo/cask-upgrade
brew tap facebook/fb
brew tap homebrew/cask-fonts
brew tap homebrew/cask-versions
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl
sudo spctl --master-disable
brew cask install adoptopenjdk adoptopenjdk8 google-chrome java mactex osxfuse xquartz
cat ${GIT_ROOT_DIR}/packages/brews | xargs brew install
brew tap vitorgalvao/tiny-scripts && brew install cask-repair
cat ${GIT_ROOT_DIR}/packages/casks | xargs brew cask install
apm install --packages-file ${GIT_ROOT_DIR}/packages/atom_packages
for extension in $(cat ${GIT_ROOT_DIR}/packages/vscode_extensions)
do
  code --install-extension ${extension}
done
export LDFLAGS="-L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib/system"
pip3 install -U cython pyyaml
pip3 install -U -r ${GIT_ROOT_DIR}/packages/pip3s
/usr/local/anaconda3/bin/conda install pytorch torchvision -c pytorch
curl -sSL https://raw.githubusercontent.com/sdispater/poetry/master/get-poetry.py | python
if [ ! -n "$ZSH" ]
then
  ZSH=~/.oh-my-zsh
fi
if [ ! -d "$ZSH" ]
then
  sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed 's:env zsh -l::g')"
  git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
  FONTS_DIR=~/.oh-my-zsh/custom/fonts
  git clone git@github.com:powerline/fonts ${FONTS_DIR}
  cd ${FONTS_DIR}
  ./install.sh
  ${GIT_ROOT_DIR}/scripts/setup-bin.sh
  ${GIT_ROOT_DIR}/scripts/setup-conf.sh
  GREEN="$(tput setaf 2)"
  NORMAL="$(tput sgr0)"
  printf "${GREEN}"
  echo 'Please update color scheme in iTerm via iTerm2 → Preferences → Profiles → Colors → Color Presets → Solarized Dark'
  echo 'Also, please update font in iTerm via iTerm2 → Preferences → Profiles → Text → Change Font → Hack Nerd Font size 14'
  echo 'You may also want to update .gitconfig'
  printf "${NORMAL}"
  env zsh -l
  mkdir $ZSH/plugins/poetry
  poetry completions zsh > $ZSH/plugins/poetry/_poetry
  git clone https://github.com/bash-my-aws/bash-my-aws.git ~/.bash-my-aws
fi
