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
# Dependencies: curl, jq

setopt ERR_EXIT PIPE_FAIL NO_UNSET

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
readonly BREW_CASK_API_URL="https://formulae.brew.sh/api/cask.json"
readonly OUTPUT_DIR="${OUTPUT_DIR:-.casks}"

# Intermediate JSON files
readonly JSON_INPUT="$OUTPUT_DIR/casks.json"
readonly JSON_STEP1="$OUTPUT_DIR/casks_step1.json"
readonly JSON_STEP2="$OUTPUT_DIR/casks_step2.json"
readonly JSON_STEP3="$OUTPUT_DIR/casks_step3.json"
readonly JSON_STEP4="$OUTPUT_DIR/casks_step4.json"
readonly JSON_STEP5="$OUTPUT_DIR/casks_step5.json"
readonly JSON_STEP6="$OUTPUT_DIR/casks_step6.json"
readonly JSON_FINAL="$OUTPUT_DIR/casks_final.json"
readonly JSON_FINAL_CUSTOM="$OUTPUT_DIR/casks_final_custom.json"

# Filter log CSV files
readonly LOG_DISABLED="$OUTPUT_DIR/casks_filtered_disabled.csv"
readonly LOG_DEPRECATED="$OUTPUT_DIR/casks_filtered_deprecated.csv"
readonly LOG_VARIANT="$OUTPUT_DIR/casks_filtered_variant.csv"
readonly LOG_ROSETTA="$OUTPUT_DIR/casks_filtered_rosetta.csv"
readonly LOG_MANUAL="$OUTPUT_DIR/casks_filtered_manual.csv"
readonly LOG_STAGE_ONLY="$OUTPUT_DIR/casks_filtered_stage_only.csv"
readonly LOG_NO_ARTIFACTS="$OUTPUT_DIR/casks_filtered_no_artifacts.csv"
readonly LOG_CUSTOM="$OUTPUT_DIR/casks_filtered_custom.csv"

# Final output files
readonly OUTPUT_CSV="$OUTPUT_DIR/casks_final.csv"
readonly OUTPUT_TXT="$OUTPUT_DIR/casks_final.txt"
readonly COMBINED_IGNORE_TXT="$OUTPUT_DIR/casks_to_ignore.txt"

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

# run_filter_step — apply a jq filter, log removed casks to CSV,
#                   write kept casks to JSON.
#
# Arguments:
#   1  Human-readable label (e.g. "Disabled casks")
#   2  Input JSON file
#   3  Output JSON file
#   4  Log CSV file
#   5  jq filter expression — evaluates to TRUE for items to REMOVE
#   6+ Optional extra jq arguments (e.g. --argjson ...)
run_filter_step() {
    local label="$1" input="$2" output="$3" log="$4" filter="$5"
    shift 5

    local count
    count=$(jq "$@" "[.[] | select($filter)] | length" "$input")
    echo "${label}: ${count} removed"

    printf 'Name,Homepage\n' > "$log"
    jq -r "$@" "[.[] | select($filter)] | .[] | [.token, .homepage] | @csv" \
        "$input" >> "$log"

    jq "$@" "[.[] | select(($filter) | not)]" "$input" > "$output"
}

# write_ignore_csv — write a <basename>.csv report for a given
#                    ignore .txt file.
#
# For every cask name listed in the ignore file (one per line), looks up the
# cask's homepage in the provided casks JSON and writes a two-column CSV:
#   Name, Homepage
#
# The output CSV is placed alongside the source file;
# e.g. casks_x.txt → casks_x.csv.
#
# Arguments:
#   1  Path to the .txt file listing cask names (one per line)
#   2  Path to the full casks JSON catalogue (used for homepage lookups)
write_ignore_csv() {
    local ignore_file="$1" casks_json="$2"
    local csv_file="${ignore_file:r}.csv"

    local names_json
    names_json=$(
        jq -R -s 'split("\n") | map(select(length > 0))' "$ignore_file"
    )

    printf 'Name,Homepage\n' > "$csv_file"
    jq -r --argjson names "$names_json" \
        '[.[] | select(.token as $t | ($names | index($t)) != null)]
         | .[] | [.token, .homepage] | @csv' \
        "$casks_json" >> "$csv_file"

    echo "  → CSV report: $csv_file"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

mkdir -p "$OUTPUT_DIR"
check_deps

# Step 1: Download cask catalogue
echo "Downloading casks from ${BREW_CASK_API_URL}..."
curl -fsSL "$BREW_CASK_API_URL" -o "$JSON_INPUT"

total=$(jq length "$JSON_INPUT")
echo "Total casks available: ${total}"

printf 'Name,Homepage\n' > "$OUTPUT_DIR/casks.csv"
jq -r '.[] | [.token, .homepage] | @csv' "$JSON_INPUT" \
    >> "$OUTPUT_DIR/casks.csv"

# Steps 2–8: Progressive filtering
run_filter_step "Disabled casks" \
    "$JSON_INPUT" "$JSON_STEP1" "$LOG_DISABLED" \
    ".disabled"
run_filter_step "Deprecated casks" \
    "$JSON_STEP1" "$JSON_STEP2" "$LOG_DEPRECATED" \
    ".deprecated"
run_filter_step "Variant casks (@)" \
    "$JSON_STEP2" "$JSON_STEP3" "$LOG_VARIANT" \
    '.token | contains("@")'
run_filter_step "Rosetta-required casks" \
    "$JSON_STEP3" "$JSON_STEP4" "$LOG_ROSETTA" \
    '.caveats // "" | test("requires rosetta"; "i")'
run_filter_step "Manual-installer casks" \
    "$JSON_STEP4" "$JSON_STEP5" "$LOG_MANUAL" \
    '[.artifacts[].installer?[]? | select(has("manual"))] | length > 0'
run_filter_step "Stage-only casks" \
    "$JSON_STEP5" "$JSON_STEP6" "$LOG_STAGE_ONLY" \
    '.artifacts | tostring | contains("stage_only")'
run_filter_step "No-interesting-artifact casks" \
    "$JSON_STEP6" "$JSON_FINAL" "$LOG_NO_ARTIFACTS" \
    '.artifacts | tostring
     | test("\"(app|binary|installer|pkg|suite)\"") | not'

# Step 9: Apply custom ignore lists (if any)
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
        cat "$file" >> "$COMBINED_IGNORE_TXT"
        write_ignore_csv "$file" "$JSON_INPUT"
    done
done

if [[ -s "$COMBINED_IGNORE_TXT" ]]; then
    blacklist_json=$(jq -R -s 'split("\n") | map(select(length > 0))' \
        "$COMBINED_IGNORE_TXT")

    run_filter_step "Custom-ignored casks" \
        "$JSON_FINAL" \
        "$JSON_FINAL_CUSTOM" \
        "$LOG_CUSTOM" \
        '.token as $t | $blacklist | index($t)' \
        --argjson blacklist "$blacklist_json"

    mv "$JSON_FINAL_CUSTOM" "$JSON_FINAL"
else
    echo "No custom ignore list provided — skipping."
    printf 'Name,Homepage\n' > "$LOG_CUSTOM"
fi

# Final output
final_count=$(jq length "$JSON_FINAL")

printf 'Name,Homepage\n' > "$OUTPUT_CSV"
jq -r '.[] | [.token, .homepage] | @csv' "$JSON_FINAL" >> "$OUTPUT_CSV"
jq -r '.[].token' "$JSON_FINAL" > "$OUTPUT_TXT"

echo "---------------------------------------------------"
echo "Final interesting casks: ${final_count}"
echo "Outputs: ${JSON_FINAL}, ${OUTPUT_CSV}, ${OUTPUT_TXT}"

# Clean up intermediate files
rm -f \
    "$JSON_STEP1" \
    "$JSON_STEP2" \
    "$JSON_STEP3" \
    "$JSON_STEP4" \
    "$JSON_STEP5" \
    "$JSON_STEP6" \
    "$COMBINED_IGNORE_TXT"
