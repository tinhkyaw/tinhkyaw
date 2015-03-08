[[ -s "$HOME/.bashrc" ]] && source "$HOME/.bashrc" # Load .bashrc

[[ -s "$HOME/.profile" ]] && source "$HOME/.profile" # Load the default .profile

if which jenv > /dev/null; then eval "$(jenv init -)"; fi
