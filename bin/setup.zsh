#!/usr/bin/env zsh
# =============================================================================
# setup.zsh — Bootstrap a new macOS machine from scratch
# =============================================================================
#
# Usage:
#   setup.zsh
#
# Description:
#   Installs and configures the full development environment:
#   Homebrew, Zsh (via setup-zsh.zsh), Doom Emacs, casks, conda,
#   npm globals, VS Code extensions, uv tools, Ruby gems, Julia,
#   Rust, OCaml (opam), and Perl (via setup-perl.zsh).
#
#   Must be run from within the dotfiles repository. Idempotent:
#   re-running after a partial failure is safe.
#
# Dependencies:
#   curl  — pre-installed on macOS; required before Homebrew is available
#
# Environment:
#   HOMEBREW_PREFIX   Set automatically by "eval brew shellenv" below
# =============================================================================

# ERR_EXIT is omitted: first-run bootstrap steps (ln, git clone) can
# legitimately fail on reruns; PIPE_FAIL and NO_UNSET are still enforced.
setopt PIPE_FAIL NO_UNSET

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Verify that the given commands are available.
#
# Arguments:
#   1+  Command names to check (e.g. curl git)
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
# Bootstrap: Homebrew
# ---------------------------------------------------------------------------

# curl is the only dependency that must exist before Homebrew is installed;
# it ships with macOS.
check_deps curl

if (( ! ${+commands[brew]} )); then
  /bin/bash -c \
    "$(curl -fsSL \
      https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  sudo spctl --global-disable
  brew developer on
  # Install coreutils first so greadlink is available for the rest of the
  # script; git and mr are needed immediately after.
  brew install coreutils fd git grep mr ripgrep
  xargs brew tap <"${0:A:h:h}/lists/taps.txt"
  brew install railwaycat/emacsmacport/emacs-mac \
    --with-modules --with-native-compilation
  # Use ln -sf so the symlink is replaced cleanly on rerun.
  ln -sf "$(brew --prefix)" "${HOME}/.brew"
fi

# Initialise the Homebrew environment. Try the Apple Silicon prefix first,
# then fall back to the Intel prefix.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  echo "Error: Homebrew not found after install — cannot continue." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Bootstrap: resolve script location and repo root
# ---------------------------------------------------------------------------

# greadlink (from coreutils) and git are now guaranteed to be available.
check_deps greadlink git

readonly DIR=$(dirname "$(greadlink -f "${0}")")
cd "${DIR}" || exit
readonly GIT_ROOT_DIR=$(git rev-parse --show-toplevel)
readonly LIST_DIR="${GIT_ROOT_DIR}/lists"

# ---------------------------------------------------------------------------
# Zsh configuration
# ---------------------------------------------------------------------------

"${GIT_ROOT_DIR}/bin/setup-zsh.zsh"

# ---------------------------------------------------------------------------
# Build environment
# ---------------------------------------------------------------------------

# Make system SDK headers visible to the C compiler.
CPATH=$(xcrun --show-sdk-path)/usr/include
export CPATH

# Link against the system SDK's libs (needed for some compiled gems/wheels).
readonly CLI_PATH='/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib/system'
export LDFLAGS="-L${CLI_PATH}"

export SLUGIFY_USES_TEXT_UNIDECODE=yes

# ---------------------------------------------------------------------------
# Homebrew formulas
# ---------------------------------------------------------------------------

xargs brew install <"${LIST_DIR}/brews.txt"

# ---------------------------------------------------------------------------
# Rust
# ---------------------------------------------------------------------------

rustup-init -y

# ---------------------------------------------------------------------------
# Doom Emacs
# ---------------------------------------------------------------------------

if [[ ! -d "${HOME}/.config/emacs" ]]; then
  git clone --depth 1 https://github.com/doomemacs/doomemacs \
    "${HOME}/.config/emacs"
  "${HOME}/.config/emacs/bin/doom" install
  # Back up any generated config.el before symlinking the managed version.
  if [[ -f "${HOME}/.config/doom/config.el" ]]; then
    mv "${HOME}/.config/doom/config.el" "${HOME}/.config/doom/config.el.BAK"
  fi
  ln -sf "${GIT_ROOT_DIR}/conf/doom/config.el" "${HOME}/.config/doom/config.el"
fi

# ---------------------------------------------------------------------------
# Sudo askpass (sourced to export SUDO_ASKPASS into the current shell)
# ---------------------------------------------------------------------------

source "${GIT_ROOT_DIR}/bin/setup-sudo-askpass.zsh"

# ---------------------------------------------------------------------------
# Homebrew casks
# ---------------------------------------------------------------------------

# Install temurin separately first — some casks depend on a JVM.
brew install --cask temurin

# Install each cask individually so a single failure does not abort the
# rest. Failures are collected and reported together at the end.
typeset -a failed_casks=()
while IFS= read -r cask; do
  [[ -z "${cask}" ]] && continue
  brew install --cask "${cask}" || failed_casks+=("${cask}")
done <"${LIST_DIR}/casks.txt"
if (( ${#failed_casks[@]} > 0 )); then
  print -P "%F{yellow}Warning: ${#failed_casks[@]} cask(s) failed to install: ${failed_casks[*]}%f"
fi

# ---------------------------------------------------------------------------
# Conda
# ---------------------------------------------------------------------------

conda init "$(basename "${SHELL}")"

# ---------------------------------------------------------------------------
# Node / npm
# ---------------------------------------------------------------------------

xargs npm install -g <"${LIST_DIR}/npms.txt"

# ---------------------------------------------------------------------------
# Editor extensions (VS Code variants)
# ---------------------------------------------------------------------------

# Guard each editor so missing editors are silently skipped.
for code_cmd in code agy cursor; do
  if command -v "${code_cmd}" &>/dev/null; then
    xargs -I {} "${code_cmd}" --install-extension {} <"${LIST_DIR}/codes.txt"
  fi
done

# ---------------------------------------------------------------------------
# Zed
# ---------------------------------------------------------------------------

mkdir -p "${HOME}/.config/zed"
ln -sf "${GIT_ROOT_DIR}/conf/zed/settings.json" \
  "${HOME}/.config/zed/settings.json"

# ---------------------------------------------------------------------------
# Python (uv tools)
# ---------------------------------------------------------------------------

# These env vars are required when building gRPC wheels from source.
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1

# Create clang-omp wrappers expected by packages that use OpenMP.
ln -sf "${HOMEBREW_PREFIX}/opt/llvm/bin/clang" \
  "${HOMEBREW_PREFIX}/bin/clang-omp"
ln -sf "${HOMEBREW_PREFIX}/opt/llvm/bin/clang++" \
  "${HOMEBREW_PREFIX}/bin/clang-omp++"
export CC=clang-omp CXX=clang-omp++

xargs -I {} uv tool install {} <"${LIST_DIR}/uvtools.txt"

# ---------------------------------------------------------------------------
# Ruby
# ---------------------------------------------------------------------------

xargs gem install <"${LIST_DIR}/gems.txt"

# ---------------------------------------------------------------------------
# Julia
# ---------------------------------------------------------------------------

juliaup add release
juliaup default release

# ---------------------------------------------------------------------------
# Rust (finalize)
# ---------------------------------------------------------------------------

rustup default stable

# ---------------------------------------------------------------------------
# OCaml
# ---------------------------------------------------------------------------

opam init -a

# ---------------------------------------------------------------------------
# Perl
# ---------------------------------------------------------------------------

# Set the Perl version expected by csshX before running the setup script.
defaults write com.apple.versioner.perl Version -string 5.18

readonly PERL_SETUP='setup-perl.zsh'
ln -sf "${GIT_ROOT_DIR}/bin/${PERL_SETUP}" "${HOME}/bin/${PERL_SETUP}"
"${GIT_ROOT_DIR}/bin/${PERL_SETUP}"
