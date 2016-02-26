#!/usr/bin/env bash
brew install git mysql python swig
brew reinstall --with-gmp coreutils
brew reinstall --with-doc --with-gdbm --with-gmp --with-libffi ruby
WD=$(pwd)
DIR=$(dirname "$(greadlink -f "$0")")
cd ${DIR}
GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
brew reinstall --with-cocoa --with-glib --with-gnutls --with-imagemagick --with-librsvg --with-mailutils emacs
brew reinstall --with-lua --with-luajit --with-override-system-vim macvim
brew reinstall --with-app --with-bindings --with-reetype --with-gts --with-librsvg --with-pango graphviz
brew reinstall --with-graphviz qcachegrind
brew reinstall --with-plugins jmeter
brew reinstall --with-gunzip --with-libressl --with-passenger --with-spdy --with-webdav nginx
brew reinstall --with-openssl node
brew reinstall --with-geoipupdate geoip
brew reinstall --with-libsmi --with-lua --with-portaudio --with-qt --with-qt5 wireshark
brew reinstall --with-dcadec --with-faac --with-fdk-aac --with-ffplay --with-fontconfig --with-freetype --with-frei0r --with-libass --with-libbluray --with-libbs2b --with-libcaca --with-libquvi --with-libsoxr --with-libssh --with-libvidstab --with-libvorbis --with-libvpx --with-opencore-amr --with-openjpeg --with-openssl --with-opus --with-rtmpdump --with-schroedinger --with-snappy --with-speex --with-theora --with-tools --with-webp --with-x265 --with-zeromq ffmpeg
cat ${GIT_ROOT_DIR}/packages/brews | xargs brew install
brew install cask
brew tap caskroom/versions
cat ${GIT_ROOT_DIR}/packages/min_casks | xargs brew cask install
brew reinstall --with-cairo --with-qt --with-tex --with-wxmac gnuplot
brew reinstall --with-audio --with-gui octave
cd ${WD}
