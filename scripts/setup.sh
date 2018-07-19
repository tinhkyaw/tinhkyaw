#!/usr/bin/env bash
if ! command -v brew &> /dev/null
then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi
brew tap facebook/fb
brew tap homebrew/science
brew install git mysql python ruby swig tmux-cssh zsh
brew install --with-gmp coreutils
pip3 install --no-binary :all: -U virtualenvwrapper
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "${0}")")
cd ${DIR}
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
if ! brew list graphviz &> /dev/null
then
  brew install --with-app --with-bindings --with-freetype --with-gts --with-librsvg --with-pango graphviz
fi
if ! brew list qcachegrind &> /dev/null
then
  brew install --with-graphviz qcachegrind
fi
if ! brew list jmeter &> /dev/null
then
  brew install --with-plugins jmeter
fi
if ! brew list nginx &> /dev/null
then
  brew install --with-gunzip --with-passenger --with-webdav nginx
fi
if ! brew list node &> /dev/null
then
  brew install node
  cat ${GIT_ROOT_DIR}/packages/npms | xargs npm install -g
fi
if ! brew list geoip &> /dev/null
then
  brew install --with-geoipupdate geoip
fi
if ! brew list ffmpeg &> /dev/null
then
  brew install --with-faac --with-fdk-aac --wtih-ffplay --with-fontconfig --with-freetype --with-frei0r --with-libass -with-libbluray --with-libbs2b --with-libcaca --with-libsoxr --with-libssh --with-libvidstab --with-libvorbis --withlibvpx --with-opencore-amr --with-openh264 --withopenjpeg --withopenssl --with-opus --with-rtmpdump --withrubberband --with-schroedinger --with-snappy --with-speex --with-theora --with-tools --with-webp --with-x265 --with-xz --with-zeromq ffmpeg
fi
brew install cask
brew tap caskroom/fonts
brew tap caskroom/versions
export HOMEBREW_CASK_OPTS="--appdir=/Applications"
brew cask install java xquartz mactex
cat ${GIT_ROOT_DIR}/packages/brews | xargs brew install
cat ${GIT_ROOT_DIR}/packages/casks | xargs brew cask install
apm install --packages-file ${GIT_ROOT_DIR}/packages/atom_packages
for extension in $(cat ${GIT_ROOT_DIR}/packages/vscode_extensions)
do
  code --install-extension ${extension}
done
if ! brew list gnuplot &> /dev/null
then
  brew install --with-cairo --with-qt5 --with-tex --with-wxmac gnuplot
fi
if ! brew list octave &> /dev/null
then
  brew install octave
fi
if ! brew list thrift &> /dev/null
then
  brew install --with-erlang --with-java --with-libevent --with-python@2 thrift
fi
if ! brew list uWSGI &> /dev/null
then
  brew install --with-geoip --with-libyaml --with-mono --with-nagios --with-postgresql --with-python --with-ruby --with-zeromq uwsgi
fi
export LDFLAGS="-L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib/system"
pip3 install --no-binary :all: -U cython pyyaml
pip3 install --no-binary :all: -U -r ${GIT_ROOT_DIR}/packages/pips
${GIT_ROOT_DIR}/scripts/setup-bin.sh
${GIT_ROOT_DIR}/scripts/setup-conf.sh
if [ ! -n "$ZSH" ]
then
  ZSH=~/.oh-my-zsh
fi
if [ ! -d "$ZSH" ]
then
  sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh); git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k; git clone git@github.com:powerline/fonts ${GIT_ROOT_DIR}/fonts; cd ${GIT_ROOT_DIR}/fonts; ./install.sh; cd ${GIT_ROOT_DIR}; rm -r ${GIT_ROOT_DIR}/fonts; source ${HOME}/.zshrc"
fi
cd ${WD}
