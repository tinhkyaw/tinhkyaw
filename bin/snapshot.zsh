#!/usr/bin/env zsh
# =============================================================================
# snapshot.zsh — Capture installed-package manifests for all package managers
# =============================================================================
#
# Usage:
#   snapshot.zsh <suffix>
#
# Arguments:
#   suffix  String appended to every snapshot filename, e.g. "-2024-01-15"
#           or "-before-upgrade". Use a date or descriptive tag.
#
# Description:
#   Writes one snapshot file per package manager to SNAPSHOT_DIR and
#   produces curated "lists" (top-level / non-dependency packages only)
#   for use with setup scripts.
#
# Outputs (snapshots):
#   $SNAPSHOT_DIR/brew<suffix>.txt      — all Homebrew formulas
#   $SNAPSHOT_DIR/cask<suffix>.txt      — all Homebrew casks
#   $SNAPSHOT_DIR/tap<suffix>.txt       — Homebrew taps
#   $SNAPSHOT_DIR/mas<suffix>.txt       — Mac App Store apps
#   $SNAPSHOT_DIR/gem<suffix>.txt       — Ruby gems
#   $SNAPSHOT_DIR/npm<suffix>.txt       — global npm packages
#   $SNAPSHOT_DIR/uv<suffix>.txt        — uv tools
#   $SNAPSHOT_DIR/conda<suffix>.txt     — Conda (anaconda3)
#   $SNAPSHOT_DIR/miniforge<suffix>.txt — Conda (base)
#   $SNAPSHOT_DIR/code<suffix>.txt      — VS Code extensions
#   $SNAPSHOT_DIR/cursor<suffix>.txt    — Cursor extensions
#   $SNAPSHOT_DIR/agy<suffix>.txt       — agy extensions
#   $SNAPSHOT_DIR/chrome<suffix>.txt    — Chrome version
#   $SNAPSHOT_DIR/gcloud<suffix>.txt    — gcloud components
#   $SNAPSHOT_DIR/mr<suffix>.txt        — mr repository config
#   $SNAPSHOT_DIR/cpan<suffix>.txt      — CPAN modules
#
# Outputs (curated lists for setup scripts):
#   <repo>/lists/brews.txt   — top-level (non-dependency) Homebrew formulas
#   <repo>/lists/casks.txt   — all Homebrew casks (sorted)
#   <repo>/lists/npms.txt    — top-level global npm packages
#   <repo>/lists/codes.txt   — VS Code extensions (minus transitive deps)
#
# Dependencies:
#   brew, mas, gem, npm, uv, conda, gcloud, cpan, jq, gsed, git, greadlink,
#   filter-casks.zsh (bundled)
#
# Environment:
#   HOMEBREW_PREFIX   Set by Homebrew (required for Conda path resolution)
#   SNAPSHOT_DIR      Override snapshot output directory
#                     (default: ~/Dropbox/Shared/Snapshots)
# =============================================================================

setopt ERR_EXIT PIPE_FAIL NO_UNSET

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
# Argument validation
# ---------------------------------------------------------------------------

if [[ $# -ne 1 ]]; then
  print -P "%F{red}Usage:%f ${0} <suffix>"
  exit 1
fi

# ---------------------------------------------------------------------------
# Bootstrap: resolve script location and repo root
# ---------------------------------------------------------------------------

# greadlink and git are required immediately; check them before use.
check_deps greadlink git

# Split assignment from readonly throughout so ERR_EXIT fires on failure
# rather than being suppressed by the readonly builtin's own exit code.
readonly SUFFIX="${1}"
readonly SNAPSHOT_DIR="${SNAPSHOT_DIR:-${HOME}/Dropbox/Shared/Snapshots}"
WD=$(pwd);             readonly WD
DIR=$(dirname "$(greadlink -f "${0}")"); readonly DIR
cd "${DIR}" || exit
GIT_ROOT_DIR=$(git rev-parse --show-toplevel); readonly GIT_ROOT_DIR
readonly LIST_DIR="${GIT_ROOT_DIR}/lists"
readonly color=blue

# Path to the Chrome binary; guarded before use below.
readonly CHROME='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

check_deps brew mas gem npm uv conda gcloud cpan jq gsed

print -P "%F{${color}}Taking snapshot...%f"

# ---------------------------------------------------------------------------
# Homebrew formulas
# ---------------------------------------------------------------------------

# Full list (for restore / diff purposes).
brew list --formula >"${SNAPSHOT_DIR}/brew${SUFFIX}.txt"

# Top-level formulas only: remove any formula that appears as a dependency
# of another installed formula, leaving just the intentionally-installed set.
{
  grep -Fvxf \
    <(brew deps --installed |
      awk -F ':' '{ print $2 }' |
      tr ' ' '\n' |
      sort -u) \
    <(brew list --formula --full-name -1 |
      sort -u)
} | sort -u >"${LIST_DIR}/brews.txt"

# ---------------------------------------------------------------------------
# Homebrew casks & taps
# ---------------------------------------------------------------------------

# Write the full cask list to both the snapshot archive and the curated list
# in a single invocation to avoid running the slow brew command twice.
brew list --cask --full-name -1 \
  | tee "${SNAPSHOT_DIR}/cask${SUFFIX}.txt" \
  | sort -u >"${LIST_DIR}/casks.txt"

brew tap >"${SNAPSHOT_DIR}/tap${SUFFIX}.txt"

# ---------------------------------------------------------------------------
# Mac App Store
# ---------------------------------------------------------------------------

mas list >"${SNAPSHOT_DIR}/mas${SUFFIX}.txt"

# ---------------------------------------------------------------------------
# Ruby
# ---------------------------------------------------------------------------

gem list >"${SNAPSHOT_DIR}/gem${SUFFIX}.txt"

# ---------------------------------------------------------------------------
# Node / npm
# ---------------------------------------------------------------------------

# Full dependency tree snapshot. npm ls exits non-zero on peer/extraneous
# dependency warnings, which is common with global packages; suppress the
# non-zero exit so it does not abort the snapshot.
npm ls -g >"${SNAPSHOT_DIR}/npm${SUFFIX}.txt" || true

# Top-level packages only (parseable output, extract package dir names).
# Suppress npm's non-zero exit and guard grep so an empty list is handled
# cleanly rather than aborting via PIPE_FAIL.
npm ls -g -p 2>/dev/null \
  | { grep node_modules || true; } \
  | xargs basename \
  >"${LIST_DIR}/npms.txt" || true

# ---------------------------------------------------------------------------
# Python (uv tools)
# ---------------------------------------------------------------------------

uv tool list >"${SNAPSHOT_DIR}/uv${SUFFIX}.txt"

# ---------------------------------------------------------------------------
# Python (Conda)
# ---------------------------------------------------------------------------

# anaconda3 environment: strip comment/directive lines, extract package names
# from the URL-per-line explicit format using awk (faster than xargs+basename),
# then strip the extension suffix. Using anchored ERE avoids matching
# ".conda" mid-name; no g flag needed as each filename has one extension.
"${HOMEBREW_PREFIX}"/anaconda3/bin/conda list \
  -p "${HOMEBREW_PREFIX}"/anaconda3 --explicit \
  | grep -v '^[#@]' \
  | awk -F'/' '{print $NF}' \
  | gsed -E 's/\.(conda|tar\.bz2)$//' \
  | sort -u \
  >"${SNAPSHOT_DIR}/conda${SUFFIX}.txt"

# base (miniforge) environment — same extraction approach.
conda list -n base --explicit \
  | grep -v '^[#@]' \
  | awk -F'/' '{print $NF}' \
  | gsed -E 's/\.(conda|tar\.bz2)$//' \
  | sort -u \
  >"${SNAPSHOT_DIR}/miniforge${SUFFIX}.txt"

# ---------------------------------------------------------------------------
# Editor extensions (VS Code variants)
# ---------------------------------------------------------------------------

# Guard each editor command so missing editors are silently skipped rather
# than aborting the entire snapshot.
for code_cmd in code agy cursor; do
  if command -v "${code_cmd}" &>/dev/null; then
    "${code_cmd}" --list-extensions --show-versions | sort -d -f \
      >"${SNAPSHOT_DIR}/${code_cmd}${SUFFIX}.txt"
  fi
done

# Curated VS Code list: filter out transitive extension dependencies and
# extension-pack members, keeping only directly-installed extensions.
# Guarded separately: `code` may not be installed (silently skipped above).
#
# A single jq -n + inputs pass replaces the original xargs-per-file jq
# calls and two subsequent jq pipes. `inputs` iterates every file given
# as arguments; `//[]` coerces absent fields to an empty array so null
# values are skipped cleanly. The result is equivalent to the three-step
# pipeline: xargs jq | jq -sS 'add|sort|unique' | jq -r '.[]|ascii_downcase'.
if command -v code &>/dev/null; then
  grep -Fvxf \
    <(jq -rn \
        '[inputs | (.extensionDependencies//[], .extensionPack//[]) | .[]] |
         map(ascii_downcase) | sort | unique | .[]' \
        $(grep -El 'extensionDependencies|extensionPack' \
            "${HOME}"/.vscode/extensions/*/package.json)) \
    <(code --list-extensions | sort -d -f) \
    >"${LIST_DIR}/codes.txt"
fi

# ---------------------------------------------------------------------------
# System & cloud tools
# ---------------------------------------------------------------------------

# Guard Chrome: the binary may not be present on all machines.
if [[ -x "${CHROME}" ]]; then
  "${CHROME}" --version >"${SNAPSHOT_DIR}/chrome${SUFFIX}.txt"
fi

# gcloud version includes a "gcloud" header line; filter it for a clean list.
gcloud version | grep -v gcloud >"${SNAPSHOT_DIR}/gcloud${SUFFIX}.txt"

# mr repository manifest — preserves the full multi-repo checkout layout.
if [[ -f "${HOME}/.mrconfig" ]]; then
  cp "${HOME}/.mrconfig" "${SNAPSHOT_DIR}/mr${SUFFIX}.txt"
fi

# ---------------------------------------------------------------------------
# CPAN (Perl modules)
# ---------------------------------------------------------------------------

cpan -l >"${SNAPSHOT_DIR}/cpan${SUFFIX}.txt"

# ---------------------------------------------------------------------------
# Cask analysis
# ---------------------------------------------------------------------------

# Run the cask filter pipeline against the already-snapshotted cask list.
# OUTPUT_DIR is set explicitly so intermediate files land in lists/.casks/
# regardless of the caller's working directory.
OUTPUT_DIR="${LIST_DIR}/.casks" "${GIT_ROOT_DIR}/bin/filter-casks.zsh" \
  "${LIST_DIR}/casks.txt" \
  "${LIST_DIR}/casks_*.txt"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

print -P "%F{${color}}$(date)%f"
cd "${WD}" || exit
