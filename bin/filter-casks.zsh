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
readonly JSON_STEP1="$OUTPUT_DIR/step1.json"
readonly JSON_STEP2="$OUTPUT_DIR/step2.json"
readonly JSON_STEP3="$OUTPUT_DIR/step3.json"
readonly JSON_STEP4="$OUTPUT_DIR/step4.json"
readonly JSON_STEP5="$OUTPUT_DIR/step5.json"
readonly JSON_STEP6="$OUTPUT_DIR/step6.json"
readonly JSON_STEP7="$OUTPUT_DIR/step7.json"
readonly JSON_FINAL="$OUTPUT_DIR/final.json"

# Filter log file names
readonly LOG_DISABLED="$OUTPUT_DIR/disabled"
readonly LOG_DEPRECATED="$OUTPUT_DIR/deprecated"
readonly LOG_VARIANT="$OUTPUT_DIR/variant"
readonly LOG_ROSETTA="$OUTPUT_DIR/rosetta"
readonly LOG_MANUAL="$OUTPUT_DIR/manual"
readonly LOG_STAGE_ONLY="$OUTPUT_DIR/stage_only"
readonly LOG_NO_ARTIFACTS="$OUTPUT_DIR/no_artifacts"
readonly LOG_CUSTOM="$OUTPUT_DIR/custom"

# Final output files
readonly OUTPUT_CSV="$OUTPUT_DIR/final.csv"
readonly OUTPUT_TXT="$OUTPUT_DIR/final.txt"
readonly COMBINED_IGNORE_TXT="$OUTPUT_DIR/ignore.txt"

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
#   4  Log file
#   5  jq filter expression — evaluates to TRUE for items to REMOVE
#   6+ Optional extra jq arguments (e.g. --argjson ...)
run_filter_step() {
    local label="$1" input="$2" output="$3" log="$4" filter="$5"
    shift 5

    local count
    count=$(jq "$@" "[.[] | select($filter)] | length" "$input")
    echo "${label}: ${count} removed"

    printf "Name,Homepage\n" > "$log.csv"
    jq -r "$@" "[.[] | select($filter)]" "$input" > "$log.json"

    jq -r "$@" ".[] | [.token, .homepage] | @csv" "$log.json" >> "$log.csv"

    jq -r "$@" ".[].token" "$log.json" > "$log.txt"


    jq "$@" "[.[] | select(($filter) | not)]" "$input" > "$output"
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

printf "Name,Homepage\n" > "$OUTPUT_DIR/casks.csv"
jq -r ".[] | [.token, .homepage] | @csv" "$JSON_INPUT" \
    >> "$OUTPUT_DIR/casks.csv"

# Steps 2–8: Progressive filtering
run_filter_step "Disabled casks" \
    "$JSON_INPUT" "$JSON_STEP1" "$LOG_DISABLED" \
    ".disabled == true"
run_filter_step "Deprecated casks" \
    "$JSON_STEP1" "$JSON_STEP2" "$LOG_DEPRECATED" \
    ".deprecated == true"
run_filter_step "Variant casks (@)" \
    "$JSON_STEP2" "$JSON_STEP3" "$LOG_VARIANT" \
    '.token | contains("@")'
run_filter_step "Rosetta-required casks" \
    "$JSON_STEP3" "$JSON_STEP4" "$LOG_ROSETTA" \
    ".caveats_rosetta == true"
run_filter_step "Manual-installer casks" \
    "$JSON_STEP4" "$JSON_STEP5" "$LOG_MANUAL" \
    '[.artifacts[].installer?[]? | select(has("manual"))] | length > 0'
run_filter_step "Stage-only casks" \
    "$JSON_STEP5" "$JSON_STEP6" "$LOG_STAGE_ONLY" \
    '.artifacts | tostring | contains("stage_only")'
run_filter_step "No-interesting-artifact casks" \
    "$JSON_STEP6" "$JSON_STEP7" "$LOG_NO_ARTIFACTS" \
    '.artifacts | tostring
     | test("\"(app|binary|installer|pkg|suite)\"") | not'

# Step 9: Apply custom ignore lists (if any)
if (( $# > 0 )); then
    "${0:h}/fetch-homepage.zsh" "$@"
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
        cat "$file" >> "$COMBINED_IGNORE_TXT"
    done
done

if [[ -s "$COMBINED_IGNORE_TXT" ]]; then
    blacklist_json=$(jq -R -s 'split("\n") | map(select(length > 0))' \
        "$COMBINED_IGNORE_TXT")
    run_filter_step "Custom-ignored casks" \
        "$JSON_STEP7" \
        "$JSON_FINAL" \
        "$LOG_CUSTOM" \
        '.token as $t | $blacklist | index($t)' \
        --argjson blacklist "$blacklist_json"
else
    echo "No custom ignore list provided — skipping."
    printf "Name,Homepage\n" > "$LOG_CUSTOM"
fi

# Final output
final_count=$(jq length "$JSON_FINAL")

printf "Name,Homepage\n" > "$OUTPUT_CSV"
jq -r ".[] | [.token, .homepage] | @csv" "$JSON_FINAL" >> "$OUTPUT_CSV"
jq -r ".[].token" "$JSON_FINAL" > "$OUTPUT_TXT"

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
    "$JSON_STEP7" \
    "$COMBINED_IGNORE_TXT"
