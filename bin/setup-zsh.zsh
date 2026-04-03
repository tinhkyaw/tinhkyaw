#!/usr/bin/env zsh
# =============================================================================
# setup-zsh.zsh — Configure Zsh, dotfiles, and editor symlinks
# =============================================================================
#
# Usage:
#   setup-zsh.zsh
#
# Description:
#   Sets up SSH config, YADR dotfiles, Zim (Zsh plugin manager), Git config,
#   dotfile symlinks (condarc, prettierrc, zimrc, zshrc, gitconfig), VS Code
#   settings for all installed editors, and ~/bin script symlinks.
#
# Dependencies:
#   curl, gsed, mr, git, greadlink
# =============================================================================

setopt ERR_EXIT PIPE_FAIL NO_UNSET

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Verify that the given commands are available.
#
# Arguments:
#   1+  Command names to check (e.g. curl gsed mr)
check_deps() {
    local missing=()
    for cmd in "$@"; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if (( ${#missing} > 0 )); then
        echo "Error: missing required dependencies: ${missing[*]}" >&2
        echo "Install with: brew install ${missing[*]}" >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Bootstrap: resolve script location and repo root
# ---------------------------------------------------------------------------

check_deps greadlink git

readonly DIR=$(dirname "$(greadlink -f "${0}")")
GIT_ROOT_DIR=$(git -C "${DIR}" rev-parse --show-toplevel)
readonly GIT_ROOT_DIR

check_deps curl gsed mr

# ---------------------------------------------------------------------------
# SSH
# ---------------------------------------------------------------------------

mkdir -p "${HOME}/.ssh"
cp "${GIT_ROOT_DIR}/conf/ssh_config" "${HOME}/.ssh/config"

# ---------------------------------------------------------------------------
# YADR dotfiles
# ---------------------------------------------------------------------------

readonly GHUC='https://raw.githubusercontent.com'

if [[ ! -d "${HOME}/.yadr" ]]; then
  sh -c \
    "$(curl -fsSL "${GHUC}/skwp/dotfiles/master/install.sh")"
  # YADR's path file uses the removed `egrep`; patch to the POSIX equivalent.
  gsed -i 's/egrep -q/grep -Eq/' "${HOME}/.yadr/zsh/0_path.zsh"
  mr register "${HOME}/.yadr"
fi

# ---------------------------------------------------------------------------
# Zim (Zsh plugin manager)
# ---------------------------------------------------------------------------

curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh \
  | zsh

# ---------------------------------------------------------------------------
# Git config
# ---------------------------------------------------------------------------

mkdir -p "${HOME}/.config/git"
ln -sf "${GIT_ROOT_DIR}/conf/git/gitattributes" \
  "${HOME}/.config/git/attributes"
# Copy (not symlink) so the user can set name/email without touching the repo.
cp "${GIT_ROOT_DIR}/conf/git/gitconfig.user" "${HOME}/.gitconfig.user"
ln -sf "${GIT_ROOT_DIR}/.gitignore" "${HOME}/.gitignore"

# ---------------------------------------------------------------------------
# Dotfile symlinks
# ---------------------------------------------------------------------------

# Remove any pre-existing ~/.inputrc that would shadow the readline config
# coming in via YADR.
if [[ -f "${HOME}/.inputrc" ]]; then
  unlink "${HOME}/.inputrc"
fi

for conf_file in \
  condarc \
  prettierrc \
  git/gitconfig \
  zsh/zimrc \
  zsh/zshrc; do
  ln -sf "${GIT_ROOT_DIR}/conf/${conf_file}" \
    "${HOME}/.$(basename "${conf_file}")"
done

# ---------------------------------------------------------------------------
# VS Code variant settings
# ---------------------------------------------------------------------------

for vscode_ide in Code Antigravity Cursor; do
  mkdir -p "${HOME}/Library/Application Support/${vscode_ide}/User"
  ln -sf "${GIT_ROOT_DIR}/conf/code/settings.json" \
    "${HOME}/Library/Application Support/${vscode_ide}/User/settings.json"
done

# ---------------------------------------------------------------------------
# ~/bin script symlinks
# ---------------------------------------------------------------------------

mkdir -p "${HOME}/bin"
for script_file in \
  diff-snap.zsh \
  filter-casks.zsh \
  s3cat \
  snapshot.zsh \
  tunnel \
  update-all.zsh \
  update-gi.zsh; do
  ln -sf "${GIT_ROOT_DIR}/bin/${script_file}" "${HOME}/bin/"
done
