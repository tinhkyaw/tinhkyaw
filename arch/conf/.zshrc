# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export TERM="xterm-256color"

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

export VIRTUALENVWRAPPER_PYTHON="/usr/local/bin/python3"

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
POWERLEVEL9K_MODE="nerdfont-complete"
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir rbenv vcs virtualenv)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs history time)
ZSH_THEME="powerlevel9k/powerlevel9k"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git poetry tmux tmux-cssh virtualenvwrapper)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

autoload colors
colors

setopt append_history         # Allow multiple terminal sessions to all append to one zsh command history
setopt extended_history       # save timestamp of command and duration
setopt inc_append_history     # Add comamnds as they are typed, don't wait until shell exit
setopt hist_expire_dups_first # when trimming history, lose oldest duplicates first
setopt hist_ignore_dups       # Do not write events to history that are duplicates of previous events
setopt hist_ignore_space      # remove command line from history list when first character on the line is a space
setopt hist_find_no_dups      # When searching history don't display results already cycled through twice
setopt hist_reduce_blanks     # Remove extra blanks from each command line being added to history
setopt share_history          # imports new commands and appends typed commands to history

DEFAULT_USER=${USER}

export PATH=${HOME}/bin:/usr/local/sbin:$PATH

export HOMEBREW_CASK_OPTS="--appdir=/Applications"

export BYOBU_PREFIX=/usr/local

GPG_TTY=$(tty)
export GPG_TTY

export CFLAGS="-I/usr/local/opt/zlib/include"
export LDFLAGS="-L/usr/local/opt/openssl/lib -L/usr/local/opt/zlib/lib"
export OPENBLAS="/usr/local/opt/openblas"

ssh-add -A &>/dev/null

if [ -x /usr/libexec/path_helper ]; then
  eval $(/usr/libexec/path_helper -s)
fi

if [ -d $(brew --prefix)/opt/python/libexec/bin ]; then
  export PATH=$PATH:$(brew --prefix)/opt/python/libexec/bin
fi

if [ -d /usr/local/anaconda3/bin ]; then
  export PATH=$PATH:/usr/local/anaconda3/bin
fi

if [ -d /usr/local/opt/ruby/bin ]; then
  export PATH=/usr/local/opt/ruby/bin:$PATH
fi

if [ -f /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if [ -f /usr/local/opt/asdf/libexec/asdf.sh ]; then
  . /usr/local/opt/asdf/libexec/asdf.sh
fi

if [ -d ${HOME}/.bash-my-aws ]; then
  export PATH="$PATH:$HOME/.bash-my-aws/bin"
  source ${HOME}/.bash-my-aws/aliases

  autoload -U +X compinit && compinit
  autoload -U +X bashcompinit && bashcompinit

  source ${HOME}/.bash-my-aws/bash_completion.sh
fi

if [ -d /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk ]; then
  source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
  source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
fi

# added by Snowflake SnowSQL installer v1.2
export PATH=/Applications/SnowSQL.app/Contents/MacOS:$PATH
