#!/usr/bin/env zsh
# fetch-homepage.zsh — Fetch latest Homebrew cask data and write CSV outputs
#                      for lists of cask names.
#
# Usage:
#   fetch-homepage.zsh <file_glob> [file_glob ...]
#
# Arguments:
#   file_glob   One or more glob patterns matching plain-text files
#               listing cask names (one per line).
#               For every matched file <name>.txt, a corresponding
#               <name>.csv is written alongside it,
#               containing columns: Name, Homepage.
#               Names within each file are sorted before writing.
#
# Dependencies: curl, jq

setopt ERR_EXIT PIPE_FAIL NO_UNSET

readonly BREW_CASK_API_URL="https://formulae.brew.sh/api/cask.json"
readonly CASKS_JSON=$(mktemp)

trap 'rm -f "$CASKS_JSON"' EXIT INT TERM

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Verify required external commands are available.
check_deps() {
    local missing=()
    for cmd in curl jq; do
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
# For every cask name listed in the file (one per line), looks up the
# cask's homepage in the provided casks JSON and writes a two-column CSV:
#   Name, Homepage
# Names are sorted before writing.
#
# The output CSV is placed alongside the source file;
# e.g. lists/casks_x.txt → lists/casks_x.csv.
#
# Arguments:
#   1  Path to the .txt file listing cask names (one per line)
#   2  Path to the full casks JSON catalogue (used for homepage lookups)
write_csv() {
    local input_file="$1" casks_json="$2"
    local csv_file="${input_file:r}.csv"

    sort -o "$input_file" "$input_file"

    local names_json
    names_json=$(
        jq -R -s 'split("\n") | map(select(length > 0))' "$input_file"
    )

    printf "Name,Homepage\n" > "$csv_file"
    jq -r --argjson names "$names_json" \
        '[.[] | select(.token as $t | ($names | index($t)) != null)]
         | sort_by(.token)
         | .[] | [.token, .homepage] | @csv' \
        "$casks_json" >> "$csv_file"

    echo "  → CSV output: $csv_file"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if (( $# == 0 )); then
    echo "Usage: ${0:t} <file_glob> [file_glob ...]" >&2
    exit 1
fi

check_deps

echo "Downloading casks from ${BREW_CASK_API_URL}..."
curl -fsSL "$BREW_CASK_API_URL" -o "$CASKS_JSON"

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
