[[ -s "$HOME/.bashrc" ]] && source "$HOME/.bashrc" # Load .bashrc

[[ -s "$HOME/.profile" ]] && source "$HOME/.profile" # Load .profile

if which jenv > /dev/null; then eval "$(jenv init - bash)"; fi
