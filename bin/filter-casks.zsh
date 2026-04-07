#!/usr/bin/env zsh
# filter-casks.zsh — Download and filter Homebrew casks,
#                    with optional ignore lists.
#
# Usage:
#   filter-casks.zsh [ignore_pattern ...]
#
# Arguments:
#   ignore_pattern  One or more glob patterns matching plain-text files
#                   that list cask names to exclude (one name per line).
#                   For every matched file <name>.txt a corresponding
#                   <name>.csv report is written alongside it,
#                   containing columns: Name, Homepage.
#
# Environment:
#   OUTPUT_DIR      Directory for intermediate and output files
#                   (default: .casks)
#
# Dependencies: curl, jq, fetch-homepage.zsh (bundled)

setopt ERR_EXIT PIPE_FAIL NO_UNSET

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
readonly BREW_CASK_API_URL="https://formulae.brew.sh/api/cask.json"
readonly OUTPUT_DIR="${OUTPUT_DIR:-.casks}"

# Rolling pipeline buffers — swap between A/B instead of numbered step
# files; adding or removing a filter step requires no renaming.
readonly _PIPE_A="$OUTPUT_DIR/_pipe_a.json"
readonly _PIPE_B="$OUTPUT_DIR/_pipe_b.json"
_pipe_cur="$_PIPE_A"
_pipe_nxt="$_PIPE_B"

# Filter log file stems
readonly LOG_DISABLED="$OUTPUT_DIR/disabled"
readonly LOG_DEPRECATED="$OUTPUT_DIR/deprecated"
readonly LOG_VARIANT="$OUTPUT_DIR/variant"
readonly LOG_ROSETTA="$OUTPUT_DIR/rosetta"
readonly LOG_MANUAL="$OUTPUT_DIR/manual"
readonly LOG_STAGE_ONLY="$OUTPUT_DIR/stage_only"
readonly LOG_NO_ARTIFACTS="$OUTPUT_DIR/no_artifacts"
readonly LOG_CUSTOM="$OUTPUT_DIR/custom"

# Persisted catalogue (raw download — kept as a useful output artifact
# and passed to fetch-homepage.zsh to avoid a redundant download).
readonly JSON_CATALOGUE="$OUTPUT_DIR/casks.json"

# Final output files
readonly JSON_FINAL="$OUTPUT_DIR/result.json"

# Intermediate merge of all caller-supplied ignore lists; removed on exit.
readonly COMBINED_IGNORE_TXT="$OUTPUT_DIR/ignore.txt"

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

# write_cask_outputs — write CSV (Name,Homepage) and TXT (token per line)
#                      from a casks JSON array file, given a shared stem.
#
# Arguments:
#   1  File stem — reads <stem>.json, writes <stem>.csv and <stem>.txt
write_cask_outputs() {
    local stem="$1"
    # Combine header and data rows in a single jq pass.
    jq -r '(["Name","Homepage"] | join(",")),
           (.[] | [.token, .homepage] | @csv)' \
        "${stem}.json" > "${stem}.csv"
    jq -r '.[].token' "${stem}.json" > "${stem}.txt"
}

# run_filter_step — apply a jq filter, log removed casks to CSV+TXT,
#                   and advance the pipeline to the kept casks.
#
# Reads from the current pipeline buffer (_pipe_cur), partitions casks
# into removed/kept in a single jq pass, writes the removed set to the
# log stem, then swaps the pipeline buffers so _pipe_cur holds the
# kept casks for the next step.
#
# Arguments:
#   1  Human-readable label (e.g. "Disabled casks")
#   2  Log file stem — writes <stem>.json, <stem>.csv, <stem>.txt
#   3  jq filter expression — evaluates to TRUE for items to REMOVE
#   4+ Optional extra jq arguments (e.g. --argjson ...)
run_filter_step() {
    local label="$1" log="$2" filter="$3"
    shift 3

    # Single jq pass over the input: partition into removed and kept.
    # Using a temp file avoids holding ~30 MB in a shell variable.
    local part_file
    part_file=$(mktemp "${TMPDIR:-/tmp}/filter-casks.XXXXXX")

    # The always block guarantees part_file is removed even if a jq
    # call below fails and ERR_EXIT fires.
    {
        jq "$@" \
            "{ removed: [.[] | select($filter)],
               kept:    [.[] | select(($filter) | not)] }" \
            "$_pipe_cur" > "$part_file"

        local count
        count=$(jq '.removed | length' "$part_file")
        echo "${label}: ${count} removed"

        jq '.removed' "$part_file" > "${log}.json"
        write_cask_outputs "$log"
        jq '.kept'    "$part_file" > "$_pipe_nxt"
    } always {
        rm -f "$part_file"
    }

    # Advance the pipeline: swap current ↔ next buffers.
    local tmp=$_pipe_cur
    _pipe_cur=$_pipe_nxt
    _pipe_nxt=$tmp
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

mkdir -p "$OUTPUT_DIR"
check_deps curl jq

# Clean up pipeline buffers and the combined ignore list on any exit,
# including early exit via ERR_EXIT or signals.
trap 'rm -f "$_PIPE_A" "$_PIPE_B" "$COMBINED_IGNORE_TXT"' EXIT INT TERM

# Step 1: Download cask catalogue
echo "Downloading cask catalogue from ${BREW_CASK_API_URL}..."
curl -fsSL "$BREW_CASK_API_URL" -o "$JSON_CATALOGUE"

# Seed the rolling pipeline from the persisted catalogue.
cp "$JSON_CATALOGUE" "$_pipe_cur"

total=$(jq length "$JSON_CATALOGUE")
echo "Total casks available: ${total}"

# Write full catalogue CSV + TXT via the shared helper.
write_cask_outputs "${JSON_CATALOGUE:r}"

# Steps 2–8: Progressive filtering
run_filter_step "Disabled casks"                "$LOG_DISABLED"     \
    '.disabled == true'

run_filter_step "Deprecated casks"              "$LOG_DEPRECATED"   \
    '.deprecated == true'

run_filter_step "Variant casks (@)"             "$LOG_VARIANT"      \
    '.token | contains("@")'

run_filter_step "Rosetta-required casks"        "$LOG_ROSETTA"      \
    '.caveats_rosetta == true'

run_filter_step "Manual-installer casks"        "$LOG_MANUAL"       \
    '[.artifacts[].installer?[]? | select(has("manual"))] | length > 0'

# "stage_only" appears as an object key in the artifacts array, e.g.
# {"stage_only": [true]}, so check for an object with that key.
run_filter_step "Stage-only casks"              "$LOG_STAGE_ONLY"   \
    '.artifacts | any(type == "object" and has("stage_only"))'

# Likewise, inspect artifact object keys directly instead of via json-cast.
run_filter_step "No-interesting-artifact casks" "$LOG_NO_ARTIFACTS" \
    '[.artifacts[] | objects | keys[] |
      select(IN("app","binary","installer","pkg","suite"))] | length == 0'

# Step 9: Apply custom ignore lists (if any)
# Pass the already-downloaded catalogue to avoid a redundant network fetch.
if (( $# > 0 )); then
    "${0:h}/fetch-homepage.zsh" --casks-json "$JSON_CATALOGUE" "$@"
fi

: > "$COMBINED_IGNORE_TXT"

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
        echo "Processing ignore file: ${file}"
        # Append file contents, then force a newline so that a file
        # missing a trailing newline does not concatenate its last
        # token with the first token of the next file.
        cat "$file" >> "$COMBINED_IGNORE_TXT"
        echo >> "$COMBINED_IGNORE_TXT"
    done
done

if [[ -s "$COMBINED_IGNORE_TXT" ]]; then
    # Build a set object for O(1) per-token lookup (same pattern as
    # write_csv in fetch-homepage.zsh).
    # Strip \r before passing to jq to tolerate CRLF-encoded ignore files.
    blacklist_set=$(tr -d '\r' < "$COMBINED_IGNORE_TXT" \
        | jq -R -s \
            'split("\n") | map(select(length > 0))
             | map({key: ., value: true}) | from_entries')
    run_filter_step "Custom-ignored casks" \
        "$LOG_CUSTOM" \
        '$blacklist[.token]' \
        --argjson blacklist "$blacklist_set"
else
    echo "No custom ignore list provided — skipping."
    # Produce empty output files so the directory layout is consistent
    # with every other filter step (which always writes .json/.csv/.txt).
    printf '[]\n' > "${LOG_CUSTOM}.json"
    printf 'Name,Homepage\n' > "${LOG_CUSTOM}.csv"
    : > "${LOG_CUSTOM}.txt"
fi

# Promote the final pipeline buffer to the named result file.
# mv is safe here: the EXIT trap uses rm -f, which silently ignores
# the now-absent path.
mv "$_pipe_cur" "$JSON_FINAL"

final_count=$(jq length "$JSON_FINAL")

write_cask_outputs "${JSON_FINAL:r}"

echo "---"
echo "Final interesting casks: ${final_count}"
echo "Outputs: ${JSON_FINAL}, ${JSON_FINAL:r}.csv, ${JSON_FINAL:r}.txt"
