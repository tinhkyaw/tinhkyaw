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
# Cask de-duplication:
#   After filter-casks.zsh produces lists/casks.csv, casks that share a
#   homepage are examined. When Homebrew renames a cask, the old and new
#   tokens can both end up installed locally. Any group whose members
#   resolve (via `brew info`) to the same current token is a duplicate:
#   every member is uninstalled and the current token is reinstalled once.
#   The cask lists are then regenerated. Casks that merely share a
#   homepage but are distinct products (e.g. free42-binary/-decimal)
#   resolve to different tokens and are left untouched.
#
# Cask list de-duplication:
#   The hand-maintained lists/casks_*.txt files can hold the same cask twice
#   — under an old and a new token, or repeated — within one list or across
#   lists. Duplicates are detected in the generated casks_*.csv reports the
#   same way as above; one entry per cask is kept (preferring the current
#   token), the rest are removed from the .txt files, and the CSVs are
#   regenerated. Nothing is installed or uninstalled at this stage.
#
# Dependencies:
#   brew, mas, gem, npm, uv, conda, gcloud, cpan, jq, gsed, git, greadlink,
#   filter-casks.zsh (bundled)
#
# Environment:
#   HOMEBREW_PREFIX   Set by Homebrew (required for Conda path resolution)
#   SNAPSHOT_DIR      Override snapshot output directory
#                     (default: ~/Dropbox/Shared/Snapshots)
#   DRY_RUN           If non-empty, report duplicate casks without
#                     changing anything (no uninstall, reinstall or list
#                     edits).
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

# Rename tmp_file over target only if tmp_file is non-empty, or target
# does not exist yet. Guards against a source command that exits 0 but
# silently produces no output (e.g. an unsupported brew flag combination)
# from clobbering a populated curated list with an empty one.
#
# Arguments:
#   1  tmp_file — freshly-generated content, removed if rejected
#   2  target   — curated list file to update in place
commit_if_nonempty() {
    local tmp_file="$1" target="$2"
    if [[ ! -s "$tmp_file" && -s "$target" ]]; then
        echo "Error: new ${target:t} would be empty; keeping existing" \
             "file (${target})" >&2
        rm -f "$tmp_file"
        exit 1
    fi
    mv "$tmp_file" "$target"
}

# Regenerate everything derived from the installed casks: the snapshot
# archive, the curated casks.txt, and the filter-casks.zsh reports
# (casks.csv and casks_*.csv, written into lists/ beside their sources).
#
# NOTE: --full-name is a formula-only option (see `brew list --help`); on
# recent brew versions, combining it with --cask silently prints nothing
# (exit 0) instead of erroring. Casks are listed by short token only —
# fetch-homepage.zsh already falls back to `brew info --cask` for any
# token it can't resolve via the official catalogue, which covers
# tap-qualified casks without needing the full name here.
#
# casks.txt is written to a temp file and committed only if non-empty, so a
# kill/crash — or brew silently returning nothing — leaves the previous
# list intact instead of truncated. OUTPUT_DIR is set explicitly so the
# filter's intermediate files land in lists/.casks/ regardless of the
# caller's working directory.
refresh_cask_lists() {
    brew list --cask -1 \
      | tee "${SNAPSHOT_DIR}/cask${SUFFIX}.txt" \
      | sort -u >"${LIST_DIR}/casks.txt.tmp"
    commit_if_nonempty "${LIST_DIR}/casks.txt.tmp" "${LIST_DIR}/casks.txt"

    OUTPUT_DIR="${LIST_DIR}/.casks" "${GIT_ROOT_DIR}/bin/filter-casks.zsh" \
      "${LIST_DIR}/casks.txt" \
      "${LIST_DIR}/casks_*.txt"
}

# Alias table mapping every known cask token — current or obsolete — to its
# current token, built once from the catalogue that filter-casks.zsh keeps in
# lists/.casks/casks.json. Avoids one slow `brew info` call per token.
typeset -A CASK_CANONICAL
CASK_CATALOGUE_LOADED=0

# Populate CASK_CANONICAL from the catalogue (idempotent; no-op if the
# catalogue is missing, in which case canonical_cask falls back to brew).
load_cask_catalogue() {
    local alias_token current
    local -r catalogue="${LIST_DIR}/.casks/casks.json"
    (( CASK_CATALOGUE_LOADED )) && return 0
    CASK_CATALOGUE_LOADED=1
    [[ -r "${catalogue}" ]] || return 0
    while IFS=$'\t' read -r alias_token current; do
        CASK_CANONICAL[${alias_token}]="${current}"
    done < <(jq -r '.[] | .token as $t | ($t, .old_tokens[]?) |
                    "\(.)\t\($t)"' "${catalogue}")
}

# Resolve a cask token to its current token. Homebrew follows renames, so an
# obsolete token resolves to its replacement.
#
# Arguments:
#   1  token — cask token, current or obsolete
# Output:
#   The current token, or nothing if it cannot be resolved.
canonical_cask() {
    local -r token="$1"
    local resolved
    load_cask_catalogue
    if (( ${+CASK_CANONICAL[${token}]} )); then
        print -r -- "${CASK_CANONICAL[${token}]}"
        return 0
    fi
    # Not in the official catalogue (e.g. a third-party tap): ask brew.
    resolved=$(brew info --json=v2 --cask "${token}" 2>/dev/null \
                 | jq -r '.casks[0].token // empty') || true
    print -r -- "${resolved}"
}

# Print cask entries (one space-separated group per line) that share a
# non-empty homepage across the given CSVs. Each entry is <csv basename>:
# <token>. These are only *candidates*: distinct products from one vendor
# share homepages too.
#
# Arguments:
#   1+  csv — files with a header row and quoted "Name","Homepage" rows
homepage_groups() {
    awk -F'","' '
        FNR > 1 {
            name = $1; sub(/^"/, "", name)
            home = $2; sub(/"$/, "", home)
            if (home == "") next
            file = FILENAME; sub(/.*\//, "", file)
            members[home] = members[home] " " file ":" name
            count[home]++
        }
        END {
            for (h in count)
                if (count[h] > 1) print substr(members[h], 2)
        }
    ' "$@"
}

# Print each set of entries that resolve to the same current token, one
# per line, as: <current token> <csv>:<token> <csv>:<token> ...
# Distinct products sharing a homepage resolve to different tokens and are
# not reported.
#
# Arguments:
#   1+  csv — files with a header row and quoted "Name","Homepage" rows
find_duplicate_casks() {
    local group entry canon
    local -a entries
    local -A seen

    # Load once here: canonical_cask runs in a subshell, so a lazy load
    # there would be repeated (and lost) on every call.
    load_cask_catalogue
    while IFS= read -r group; do
        seen=()
        for entry in ${=group}; do
            canon=$(canonical_cask "${entry#*:}")
            if [[ -z "${canon}" ]]; then
                echo "Warning: cannot resolve cask '${entry#*:}';" \
                     "skipping" >&2
                continue
            fi
            seen[${canon}]+="${entry} "
        done
        for canon in "${(@k)seen}"; do
            entries=( ${=seen[${canon}]} )
            if (( ${#entries} > 1 )); then
                print -r -- "${canon} ${entries[*]}"
            fi
        done
    done < <(homepage_groups "$@")
}

# Detect renamed casks installed under more than one token and reinstall
# each of them once.
#
# Arguments:
#   1  csv — casks.csv produced by filter-casks.zsh
# Returns:
#   0 if any duplicate was found (lists should be regenerated), 1 if not.
dedupe_casks() {
    local line canon token found=1
    local -a members

    while IFS= read -r line; do
        found=0
        members=( ${=line} )
        canon="${members[1]}"
        members=( ${members[2,-1]#*:} )
        print -P "%F{yellow}Duplicate cask:%f ${canon}" \
            "(installed as: ${members[*]})"
        [[ -n "${DRY_RUN:-}" ]] && continue

        # Uninstall every token, then install the current one once. A
        # failed step is reported but must not abort the snapshot.
        for token in "${members[@]}"; do
            brew uninstall --cask --force "${token}" \
                || echo "Warning: failed to uninstall '${token}'" >&2
        done
        brew install --cask "${canon}" \
            || echo "Warning: failed to reinstall '${canon}'" >&2
    done < <(find_duplicate_casks "$1")

    return ${found}
}

# Rewrite a curated cask list: drop and rename tokens, and collapse repeated
# lines. Blank and comment lines are preserved verbatim. A list that was
# sorted stays sorted.
#
# Arguments:
#   1  list   — path to the casks_*.txt file (updated in place)
#   2  drops  — space-separated tokens to remove
#   3  renames — space-separated old=new pairs
rewrite_cask_list() {
    local -r list="$1"
    local line tmp pair token
    local -A dropped renamed seen
    local sorted=0

    for token in ${=2}; do dropped[${token}]=1; done
    for pair in ${=3}; do renamed[${pair%%=*}]="${pair#*=}"; done
    sort -c "${list}" 2>/dev/null && sorted=1

    tmp=$(mktemp "${list}.XXXXXX")
    while IFS= read -r line || [[ -n "${line}" ]]; do
        if [[ -n "${line}" && "${line}" != \#* ]]; then
            (( ${+dropped[${line}]} )) && continue
            line="${renamed[${line}]:-${line}}"
            (( ${+seen[${line}]} )) && continue
            seen[${line}]=1
        fi
        print -r -- "${line}"
    done <"${list}" >"${tmp}"
    (( sorted )) && sort -o "${tmp}" "${tmp}"
    mv "${tmp}" "${list}"
}

# Remove duplicate casks within and across the manually maintained
# casks_*.txt lists, as detected in their generated casks_*.csv reports.
# Of each duplicate set, one entry survives: preferably one already using
# the current token (else the first, renamed to the current token); the
# rest are removed. Nothing is installed or uninstalled.
#
# Arguments:
#   1  list_dir — directory holding casks_*.csv and casks_*.txt
# Returns:
#   0 if any duplicate was found (CSVs should be regenerated), 1 if not.
dedupe_cask_lists() {
    local -r list_dir="$1"
    local line canon entry file token keeper found=1
    local -a csvs entries
    local -A drops renames touched
    csvs=( "${list_dir}"/casks_*.csv(N) )
    (( ${#csvs} > 0 )) || return 1

    while IFS= read -r line; do
        found=0
        entries=( ${=line} )
        canon="${entries[1]}"
        entries=( "${entries[@]:1}" )
        print -P "%F{yellow}Duplicate in lists:%f ${canon}" \
            "(${entries[*]})"

        keeper="${entries[1]}"
        for entry in "${entries[@]}"; do
            if [[ "${entry#*:}" == "${canon}" ]]; then
                keeper="${entry}"
                break
            fi
        done

        for entry in "${entries[@]}"; do
            file="${entry%%:*}" token="${entry#*:}"
            touched[${file}]=1
            # Repeats of the keeper itself are collapsed by the rewrite.
            [[ "${entry}" == "${keeper}" ]] && continue
            drops[${file}]+="${token} "
        done
        file="${keeper%%:*}" token="${keeper#*:}"
        if [[ "${token}" != "${canon}" ]]; then
            renames[${file}]+="${token}=${canon} "
        fi
    done < <(find_duplicate_casks "${csvs[@]}")

    if [[ -z "${DRY_RUN:-}" ]]; then
        for file in "${(@k)touched}"; do
            rewrite_cask_list "${list_dir}/${file:r}.txt" \
                "${drops[${file}]:-}" "${renames[${file}]:-}"
        done
    fi
    return ${found}
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
# Written to a temp file first and committed only if non-empty, so a
# kill/crash — or an upstream brew command silently returning nothing —
# leaves the curated list intact instead of truncated.
{
  grep -Fvxf \
    <(brew deps --installed |
      awk -F ':' '{ print $2 }' |
      tr ' ' '\n' |
      sort -u) \
    <(brew list --formula --full-name -1 |
      sort -u)
} | sort -u >"${LIST_DIR}/brews.txt.tmp"
commit_if_nonempty "${LIST_DIR}/brews.txt.tmp" "${LIST_DIR}/brews.txt"

# ---------------------------------------------------------------------------
# Homebrew casks & taps
# ---------------------------------------------------------------------------

# Cask lists are generated in the "Cask analysis" section below.
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
# cleanly rather than aborting via PIPE_FAIL. Written to a temp file and
# committed only if non-empty, so a kill/crash — or npm silently
# returning nothing — leaves the previous list intact.
npm ls -g -p 2>/dev/null \
  | { grep node_modules || true; } \
  | xargs basename \
  >"${LIST_DIR}/npms.txt.tmp" || true
commit_if_nonempty "${LIST_DIR}/npms.txt.tmp" "${LIST_DIR}/npms.txt"

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
for code_cmd in code; do
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
    >"${LIST_DIR}/codes.txt.tmp"
  commit_if_nonempty "${LIST_DIR}/codes.txt.tmp" "${LIST_DIR}/codes.txt"
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

refresh_cask_lists

# Both checks read the reports just generated and are independent of each
# other, so run both and regenerate once if either changed anything.
#
#  - Renamed casks can leave the old and new tokens both installed.
#  - The casks_*.txt lists are maintained by hand, so the same cask may be
#    listed twice (under an old and a new token), within or across lists.
cask_changes=0
dedupe_casks "${LIST_DIR}/casks.csv" && cask_changes=1
dedupe_cask_lists "${LIST_DIR}" && cask_changes=1
if (( cask_changes )) && [[ -z "${DRY_RUN:-}" ]]; then
  refresh_cask_lists
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

print -P "%F{${color}}$(date)%f"
cd "${WD}" || exit
