#!/usr/bin/env zsh
# fetch-homepage.zsh — Fetch latest Homebrew cask data and write CSV outputs
#                      for lists of cask names.
#
# Usage:
#   fetch-homepage.zsh [--casks-json <path>] <file_glob> [file_glob ...]
#
# Options:
#   --casks-json <path>  Use an already-downloaded cask catalogue JSON
#                        instead of fetching it from the Homebrew API.
#                        Useful when called from filter-casks.zsh to avoid
#                        a redundant network round-trip.
#
# Arguments:
#   file_glob   One or more glob patterns matching plain-text files
#               listing cask names (one per line).
#               For every matched file <name>.txt, a corresponding
#               <name>.csv is written alongside it,
#               containing columns: Name, Homepage.
#               The source .txt file is sorted in-place; the CSV rows
#               follow the same order.
#
# Fallback:
#   Casks not found in the public catalogue (e.g. installed from external
#   taps) are resolved individually via `brew info --cask`. Casks that
#   cannot be resolved by either method are warned and omitted.
#
# Dependencies: brew, curl, gsed, jq

setopt ERR_EXIT PIPE_FAIL NO_UNSET

readonly BREW_CASK_API_URL="https://formulae.brew.sh/api/cask.json"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Verify that the given commands are available.
#
# Arguments:
#   1+  Command names to check (e.g. curl jq)
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

# write_csv — write a <basename>.csv output for a given cask list file.
#
# For every cask name listed in the input file (one per line), looks up
# the cask's homepage first in the provided cask catalogue JSON (O(1) set
# lookup), then falls back to `brew info --cask` for any token not found
# there (covers casks installed from external taps). Casks that cannot be
# resolved by either method are warned and omitted from the output.
#
# The source file is sorted in-place. The output CSV is placed alongside
# it; e.g. lists/my-casks.txt → lists/my-casks.csv. Rows are sorted by
# cask token.
#
# Arguments:
#   1  Path to the .txt file listing cask names (one per line)
#   2  Path to the full casks catalogue JSON
write_csv() {
    local input_file="$1" casks_json="$2"
    local csv_file="${input_file:r}.csv"

    # Sort the input file in-place, then build a JSON array of names.
    # Strip \r before parsing to tolerate CRLF-encoded input files.
    sort -o "$input_file" "$input_file"
    local names_json
    names_json=$(tr -d '\r' < "$input_file" \
        | jq -R -s 'split("\n") | map(select(length > 0))')

    # Phase 1: catalogue lookup.
    # Build a lookup set from $names so each .token check is O(1);
    # IN($names[]) would be O(n) per entry (linear scan, no early exit).
    local catalogue_rows
    catalogue_rows=$(jq -r --argjson names "$names_json" \
        '($names | map({key: ., value: true}) | from_entries) as $set |
         [.[] | select($set[.token])]
         | sort_by(.token)
         | .[] | [.token, .homepage] | @csv' \
        "$casks_json")

    # Phase 2: identify tokens absent from the catalogue.
    local -a misses
    misses=($(jq -r --argjson names "$names_json" \
        '($names | map({key: ., value: true}) | from_entries) as $set |
         ($set | keys) - [.[] | select($set[.token]) | .token] | .[]' \
        "$casks_json"))

    # Phase 3: resolve misses via `brew info --cask` (external-tap casks).
    #
    # Two subtleties handled here:
    #   • Use .full_token (e.g. "owner/tap/name") not .token ("name"), so the
    #     CSV key matches the tap-qualified form stored in the input file.
    #   • Some cask descriptions contain a literal newline before the closing
    #     quote — a brew bug that produces invalid JSON. Sanitize with
    #     gsed -z before handing to jq: the pattern \n"[,}] matches a bare
    #     newline immediately before a closing string quote at a field or
    #     object boundary, which is the exact malformed sequence brew emits
    #     and can never appear as structural whitespace in valid JSON.
    local -a fallback_rows=()
    local cask result
    for cask in "${misses[@]}"; do
        result=$(brew info --cask "$cask" --json=v2 2>/dev/null) || {
            echo "  Warning: '$cask' not found in catalogue or via brew info"\
                 "— skipping" >&2
            continue
        }
        fallback_rows+=("$(printf '%s' "$result" \
            | gsed -z 's/\n"\([,}]\)/\\n"\1/g' \
            | jq -r '.casks[] | [.full_token, .homepage] | @csv')")
    done

    # Write header then all rows (catalogue + fallback) sorted by token.
    {
        echo 'Name,Homepage'
        { printf '%s\n' "$catalogue_rows" "${fallback_rows[@]}"; } \
            | grep -v '^$' \
            | sort -t, -k1
    } > "$csv_file"

    echo "  → CSV output: $csv_file"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

# Parse optional --casks-json flag before positional arguments.
casks_json_path=""
while [[ $# -gt 0 && "$1" == --* ]]; do
    case "$1" in
        --casks-json)
            [[ -z "${2:-}" ]] && {
                echo "Error: --casks-json requires a path argument" >&2
                exit 1
            }
            casks_json_path="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Error: unknown option '$1'" >&2
            exit 1
            ;;
    esac
done

if (( $# == 0 )); then
    echo "Usage: ${0:t} [--casks-json <path>] <file_glob> [file_glob ...]" >&2
    exit 1
fi

# brew and gsed are always needed (fallback path); curl only when downloading.
if [[ -n "$casks_json_path" ]]; then
    check_deps brew gsed jq
    if [[ ! -f "$casks_json_path" ]]; then
        echo "Error: --casks-json path not found: ${casks_json_path}" >&2
        exit 1
    fi
    CASKS_JSON="$casks_json_path"
    # Caller owns this file; no cleanup trap needed.
else
    check_deps brew curl gsed jq
    CASKS_JSON=$(mktemp "${TMPDIR:-/tmp}/fetch-homepage.XXXXXX")
    trap 'rm -f "$CASKS_JSON"' EXIT INT TERM
    echo "Downloading cask catalogue from ${BREW_CASK_API_URL}..."
    curl -fsSL "$BREW_CASK_API_URL" -o "$CASKS_JSON"
fi
readonly CASKS_JSON

for pattern in "$@"; do
    expanded_files=(${~pattern}(N))

    if (( ${#expanded_files} == 0 )); then
        echo "Warning: no files matched pattern '${pattern}'" >&2
        continue
    fi

    for file in "${expanded_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            echo "Warning: '${file}' is not a regular file — skipping" >&2
            continue
        fi
        echo "Processing file: ${file}"
        write_csv "$file" "$CASKS_JSON"
    done
done
