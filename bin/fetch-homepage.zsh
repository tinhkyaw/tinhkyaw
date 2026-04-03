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
# Dependencies: curl, jq

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
# the cask's homepage in the provided cask catalogue JSON and writes a
# two-column CSV: Name, Homepage. Rows are sorted by name.
#
# The source file is sorted in-place. The output CSV is placed alongside
# it; e.g. lists/my-casks.txt → lists/my-casks.csv.
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

    # Single jq pass: filter matching casks, sort, emit header + rows.
    # Build a lookup object from $names so each .token check is O(1);
    # IN($names[]) would be O(n) per entry (linear scan, no early exit
    # on the full catalogue).
    jq -r --argjson names "$names_json" \
        '($names | map({key: ., value: true}) | from_entries) as $set |
         (["Name","Homepage"] | join(",")),
         ([.[] | select($set[.token])]
          | sort_by(.token)
          | .[] | [.token, .homepage] | @csv)' \
        "$casks_json" > "$csv_file"

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

# When --casks-json is provided, curl is not used; skip that check.
if [[ -n "$casks_json_path" ]]; then
    check_deps jq
    if [[ ! -f "$casks_json_path" ]]; then
        echo "Error: --casks-json path not found: ${casks_json_path}" >&2
        exit 1
    fi
    CASKS_JSON="$casks_json_path"
    # Caller owns this file; no cleanup trap needed.
else
    check_deps curl jq
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
