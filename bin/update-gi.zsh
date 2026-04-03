#!/usr/bin/env zsh
# =============================================================================
# update-gi.zsh — Regenerate .gitignore from gitignore.io templates
# =============================================================================
#
# Usage:
#   update-gi.zsh
#
# Description:
#   Reads template names from lists/gis.txt, fetches the combined template
#   from the gitignore.io API, applies local patches to comment out rules
#   that conflict with project conventions (bin/, Makefile, public/), then
#   appends any extra patterns not covered by the upstream templates.
#
# Dependencies:
#   curl, awk, gsed, git, greadlink
# =============================================================================

setopt ERR_EXIT PIPE_FAIL NO_UNSET

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Verify that the given commands are available.
#
# Arguments:
#   1+  Command names to check (e.g. curl awk gsed)
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

check_deps curl awk gsed

# ---------------------------------------------------------------------------
# Build template list
# ---------------------------------------------------------------------------

print -P "%F{${color}}Updating gitignore%f"

# Read template names (one per line, first field only) and join with commas
# for the gitignore.io API. The trailing comma produced by awk is stripped.
# Split assignment from readonly so ERR_EXIT fires if awk or gsed fails.
template_list=$(
  awk -vORS=, '{ print $1 }' "${GIT_ROOT_DIR}/lists/gis.txt" |
  gsed -e 's/,$//'
)
readonly template_list

# ---------------------------------------------------------------------------
# Fetch and patch
# ---------------------------------------------------------------------------

# Fetch the combined template and comment out rules that conflict with
# project conventions:
#   ^bin, ^bin/   — legitimately tracked source directories in this repo
#   [Bb]in        — same, case-insensitive variant
#   \*/Makefile   — Makefiles are tracked
#   /public/      — converted to **/public/ for recursive matching
curl -fsSLw "\n" \
  "https://www.toptal.com/developers/gitignore/api/${template_list}" |
  gsed -e \
    's/^bin/# &/;
    s/^bin\//# &/;
    s/\[Bb\]in/# &/;
    s/\*\/Makefile/# &/;
    s/\/public/**&/;' \
  >"${GIT_ROOT_DIR}/.gitignore"

# ---------------------------------------------------------------------------
# Append extra patterns
# ---------------------------------------------------------------------------

# Patterns not covered by gitignore.io templates.
additional_patterns=(
  '**/.genaiscript/**'
  '**/.casks'
)
readonly additional_patterns
printf '%s\n' "${additional_patterns[@]}" >>"${GIT_ROOT_DIR}/.gitignore"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

cd "${WD}" || exit
