#!/usr/bin/env bash
if [[ $# -ne 1 ]]
then
  echo -e "\e[91mUsage:\e[0m ${0} <suffix>"
  exit 1
fi
SUFFIX="${1}"
if [ "${SUFFIX}" = "w" ]
then
  BREWS="min_brews"
  CASKS="min_casks"
else
  BREWS="brews"
  CASKS="casks"
fi
if ! command -v brew &> /dev/null
then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  brew tap facebook/fb
  brew tap homebrew/science
  brew install git mysql python swig tmux-cssh zsh
  sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  brew install --with-gmp coreutils
  brew install --with-doc --with-gdbm --with-gmp --with-libffi ruby
  gem install cocoapods
  pip install --no-binary :all: --upgrade virtualenvwrapper
fi
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "${0}")")
cd ${DIR}
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
${GIT_ROOT_DIR}/scripts/setup-bin.sh
${GIT_ROOT_DIR}/scripts/setup-conf.sh
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
  brew install --with-gunzip --with-libressl --with-passenger --with-spdy --with-webdav nginx
fi
if ! brew list node &> /dev/null
then
  brew install --with-openssl node
  for package in $(cat ${GIT_ROOT_DIR}/packages/npms)
  do
    npm install -g ${package}
  done
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
brew tap caskroom/versions
brew cask install java xquartz mactex
cat ${GIT_ROOT_DIR}/packages/${BREWS} | xargs brew install
source ${HOME}/.zshrc
cat ${GIT_ROOT_DIR}/packages/${CASKS} | xargs brew cask install
if ! brew list gnuplot &> /dev/null
then
  brew install --with-cairo --with-qt5 --with-tex --with-wxmac gnuplot
fi
if ! brew list graphviz &> /dev/null
then
  brew install --with-app --with-bindings --with-freetype --with-gts --with-librsvg --with-pango graphviz
fi
if ! brew list neo4j &> /dev/null
then
  brew install neo4j
fi
if ! brew list octave &> /dev/null
then
  brew install --with-docs --with-libsndfile --with-portaudio octave
fi
pip install --no-binary :all: --upgrade scipy
pip install --no-binary :all: --upgrade -r ${GIT_ROOT_DIR}/packages/pips
cd ${WD}
