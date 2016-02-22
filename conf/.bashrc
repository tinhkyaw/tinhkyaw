if [ -x /usr/libexec/path_helper ]
then
  eval $(/usr/libexec/path_helper -s)
fi
if [ -f /usr/local/etc/bash_completion.d/git-prompt.sh ]
then
  source /usr/local/etc/bash_completion.d/git-prompt.sh
fi
if [ -f /usr/local/bin/virtualenvwrapper.sh ]
then
  source /usr/local/bin/virtualenvwrapper.sh
fi
if which jenv > /dev/null
then
  eval "$(jenv init - bash)"
fi
export CLICOLOR=1
export PS1='[\[\033[01;33m\]\u\[\033[36m\]@\h\[\033[31m\]:\[\033[01;34m\]\W$(__git_ps1 "\[\033[31m\]:\[\033[32m\]%s")\[\033[00m\]]\$ '
export HISTCONTROL=erasedups
export HISTSIZE= HISTFILESIZE=
shopt -s histappend
export HOMEBREW_CASK_OPTS="--appdir=/Applications"
