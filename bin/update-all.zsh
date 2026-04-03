#!/usr/bin/env zsh
# =============================================================================
# update-all.zsh — Update all system packages, runtimes, and tools
# =============================================================================
#
# Usage:
#   update-all.zsh
#
# Description:
#   Runs a full system update sweep across Homebrew, macOS Software Update,
#   Mac App Store, Ruby gems, npm global packages, Python uv tools, Rust
#   toolchains, Conda environments, R packages, Google Cloud SDK, Doom
#   Emacs, Zim (Zsh plugin manager), mr-managed repos, and CPAN modules.
#
# Dependencies:
#   brew, mas, gem, npm, npm-check, uv, rustup, conda, gcloud,
#   doom, mr, cpan-outdated, cpanm, Rscript, timeout, git, greadlink
#
# Environment:
#   HOMEBREW_PREFIX   Set by Homebrew (required for Conda path resolution)
#   ZDOTDIR           Optional; falls back to $HOME for Zim location
# =============================================================================

# ERR_EXIT is intentionally omitted: several tools below (brew doctor,
# mas outdated) return non-zero to signal informational states, not failures.
setopt PIPE_FAIL NO_UNSET

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Verify that the given commands are available.
#
# Arguments:
#   1+  Command names to check (e.g. brew mas gem)
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

# greadlink and git are required immediately; check them before use.
check_deps greadlink git

readonly WD=$(pwd)
readonly DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}" || exit
readonly GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
readonly color=blue
readonly ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim

check_deps \
    brew mas gem npm npm-check uv rustup conda gcloud \
    doom mr cpan-outdated cpanm Rscript timeout

# ---------------------------------------------------------------------------
# Homebrew
# ---------------------------------------------------------------------------

brew update
brew upgrade --greedy
# brew cu -ay     # uncomment to upgrade casks via brew-cask-upgrade
brew cleanup -s
brew doctor      # informational; non-zero exit does not abort (no ERR_EXIT)

# ---------------------------------------------------------------------------
# macOS Software Update & Mac App Store
# ---------------------------------------------------------------------------

/usr/sbin/softwareupdate -ia
mas outdated     # exits non-zero when outdated apps exist; expected
# mas upgrade    # uncomment to auto-upgrade App Store apps

# ---------------------------------------------------------------------------
# Ruby
# ---------------------------------------------------------------------------

gem update --system
gem cleanup

# ---------------------------------------------------------------------------
# Node / npm
# ---------------------------------------------------------------------------

# Timeout guards against hung interactive prompts in npm-check.
timeout --foreground 3m npm-check -g -y

# ---------------------------------------------------------------------------
# Python (uv tools)
# ---------------------------------------------------------------------------

uv tool upgrade --all

# ---------------------------------------------------------------------------
# Python (Conda — anaconda3 + base)
# ---------------------------------------------------------------------------

# These env vars are required when building gRPC wheels from source.
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1
export CC=clang-omp CXX=clang-omp++

"${HOMEBREW_PREFIX}"/anaconda3/bin/conda update \
  -p "${HOMEBREW_PREFIX}"/anaconda3 --all -y
conda update -n base --all -y

# ---------------------------------------------------------------------------
# Rust
# ---------------------------------------------------------------------------

rustup update

# ---------------------------------------------------------------------------
# Google Cloud SDK
# ---------------------------------------------------------------------------

gcloud components update -q

# ---------------------------------------------------------------------------
# Doom Emacs
# ---------------------------------------------------------------------------

doom env
doom sync
doom -! upgrade

# ---------------------------------------------------------------------------
# R
# ---------------------------------------------------------------------------

Rscript "${GIT_ROOT_DIR}/bin/update.R"

# ---------------------------------------------------------------------------
# Zim (Zsh plugin manager)
# ---------------------------------------------------------------------------

if [[ -s "${ZIM_HOME}/init.zsh" ]]; then
  source "${ZIM_HOME}/init.zsh"
  zimfw upgrade -v
  zimfw update -v
fi

# ---------------------------------------------------------------------------
# mr — manage multiple repositories
# ---------------------------------------------------------------------------

cd "${HOME}" || exit
mr -j5 update

# ---------------------------------------------------------------------------
# Gitignore
# ---------------------------------------------------------------------------

"${DIR}/update-gi.zsh"

# ---------------------------------------------------------------------------
# CPAN (Perl modules)
# ---------------------------------------------------------------------------

print -P "%F{${color}}Updating cpan packages%f"
cpan-outdated --exclude-core | cpanm

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

print -P "%F{${color}}$(date)%f"
cd "${WD}" || exit
