#!/usr/bin/env bash
if ! command -v brew &> /dev/null
then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  brew install git mysql python swig
  brew install --with-gmp coreutils
  brew install --with-doc --with-gdbm --with-gmp --with-libffi ruby
fi
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "$0")")
cd ${DIR}
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
${GIT_ROOT_DIR}/scripts/setup-conf.sh
if ! brew list emacs &> /dev/null
then
  brew install --with-cocoa --with-glib --with-gnutls --with-imagemagick --with-librsvg --with-mailutils emacs
fi
if ! brew list macvim &> /dev/null
then
  brew install --with-lua --with-luajit --with-override-system-vim macvim
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
fi
if ! brew list geoip &> /dev/null
then
  brew install --with-geoipupdate geoip
fi
if ! brew list wireshark &> /dev/null
then
  brew install --with-libsmi --with-lua --with-portaudio --with-qt --with-qt5 wireshark
fi
if ! brew list ffmpeg &> /dev/null
then
  brew install --with-dcadec --with-faac --with-fdk-aac --with-ffplay --with-fontconfig --with-freetype --with-frei0r --with-libass --with-libbluray --with-libbs2b --with-libcaca --with-libquvi --with-libsoxr --with-libssh --with-libvidstab --with-libvorbis --with-libvpx --with-opencore-amr --with-openjpeg --with-openssl --with-opus --with-rtmpdump --with-schroedinger --with-snappy --with-speex --with-theora --with-tools --with-webp --with-x265 --with-zeromq ffmpeg
fi
cat ${GIT_ROOT_DIR}/packages/brews | xargs brew install
if ! brew list cask &> /dev/null
then
  brew install cask
  brew tap caskroom/versions
  cat ${GIT_ROOT_DIR}/packages/casks | xargs brew cask install
fi
if ! brew list gnuplot &> /dev/null
then
  brew install --with-aquaterm --with-cairo --with-latex --with-qt --with-wxmac gnuplot
fi
if ! brew list octave &> /dev/null
then
  brew install --with-audio --with-gui octave
fi
if ! brew list graphviz &> /dev/null
then
  brew install --with-app --with-bindings --with-reetype --with-gts --with-librsvg --with-pango graphviz
fi
if ! brew list qcachegrind &> /dev/null
then
  brew install --with-graphviz qcachegrind
fi
pip install --no-use-wheel --upgrade scipy
cat ${GIT_ROOT_DIR}/packages/pips | xargs pip install --no-use-wheel --upgrade
cd ${WD}
