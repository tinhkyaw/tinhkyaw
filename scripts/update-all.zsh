#!/usr/bin/env zsh
DIR=$(dirname $(type -a "${0}" | cut -d " " -f 3))
is_quick=false
while getopts q flag
do
  case ${flag} in
    q)
      is_quick=true
      ;;
    ?)
    exit 1
    ;;
  esac
done
shift $(( OPTIND - 1 ))
brew update
brew upgrade
brew upgrade cask
caskroom_path="/usr/local/Caskroom"
for app in $(brew cask list)
do
  ver=$(brew cask info ${app} | head -1 | cut -d " " -f 2)
  if [ ${ver} = "latest" ]
  then
    if grep -Fxq ${app} "$(readlink ${DIR}/ignored)"
    then
      print -P "%F{yellow}Ignoring %F{cyan}${app}%f"
    else
      if ${is_quick} && grep -Fxq ${app} "$(readlink ${DIR}/slow)"
      then
        print -P "%F{yellow}Skipping %F{cyan}${app}%f update for speed"
      else
        print -P "%F{yellow}Reinstalling%f ${ver} %F{cyan}${app}%f"
        brew cask reinstall ${app}
      fi
    fi
  else
    if [ -d "${caskroom_path}/${app}/.metadata/${ver}" ]
    then
      print -P "%F{blue}Latest %F{cyan}${app}: ${ver}%f already installed"
    else
      brew cask reinstall ${app}
    fi
  fi
done
brew cleanup -s
brew cask cleanup
cleanup-caskroom.zsh
brew doctor
gem update --system
gem update
gem cleanup
npm update -g
npm-check -u -g
pip install --upgrade pip setuptools
pip freeze --local | grep -v Jinja2 | grep -v "^\-e" | cut -d = -f 1  | xargs pip install --no-binary :all: --upgrade
