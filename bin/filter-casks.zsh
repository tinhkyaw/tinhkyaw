#!/usr/bin/env zsh

# Define the API URL
URL="https://formulae.brew.sh/api/cask.json"
OUTPUT_DIR="${OUTPUT_DIR:-.casks}"
mkdir -p "$OUTPUT_DIR"
INPUT_FILE="$OUTPUT_DIR/casks.json"

# Intermediate JSON files
CASKS_STEP1="$OUTPUT_DIR/casks_step1.json"
CASKS_STEP2="$OUTPUT_DIR/casks_step2.json"
CASKS_STEP3="$OUTPUT_DIR/casks_step3.json"
CASKS_STEP4="$OUTPUT_DIR/casks_step4.json"
CASKS_STEP5="$OUTPUT_DIR/casks_step5.json"
CASKS_STEP6="$OUTPUT_DIR/casks_step6.json"
CASKS_FINAL="$OUTPUT_DIR/casks_final.json"
CASKS_FINAL_CUSTOM="$OUTPUT_DIR/casks_final_custom.json"

# Log files
LOG_DISABLED="$OUTPUT_DIR/casks_filtered_disabled.csv"
LOG_DEPRECATED="$OUTPUT_DIR/casks_filtered_deprecated.csv"
LOG_VARIANT="$OUTPUT_DIR/casks_filtered_variant.csv"
LOG_ROSETTA="$OUTPUT_DIR/casks_filtered_rosetta.csv"
LOG_MANUAL="$OUTPUT_DIR/casks_filtered_manual.csv"
LOG_STAGE_ONLY="$OUTPUT_DIR/casks_filtered_stage_only.csv"
LOG_NO_ARTIFACTS="$OUTPUT_DIR/casks_filtered_no_artifacts.csv"
LOG_CUSTOM="$OUTPUT_DIR/casks_filtered_custom.csv"

# Output files
OUTPUT_CSV="$OUTPUT_DIR/casks_final.csv"
OUTPUT_TXT="$OUTPUT_DIR/casks_final.txt"
IGNORE_FILE="$OUTPUT_DIR/casks_to_ignore.txt"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it" \
         "(e.g., brew install jq) to run this script."
    exit 1
fi

# Function to run a filter step
# Arguments:
# 1. Message label (e.g., "Disabled casks")
# 2. Input JSON file
# 3. Output JSON file
# 4. Log text file
# 5. jq filter expression (identifies items to REMOVE)
# 6+. Optional: extra jq arguments (e.g., --argjson ...)
run_filter_step() {
    local message="$1"
    local input_file="$2"
    local output_file="$3"
    local log_file="$4"
    local filter_expr="$5"
    shift 5

    # Count items to remove
    local count
    count=$(jq "$@" "[.[] | select($filter_expr)] | length" "$input_file")
    echo "${message} found: ${count}"

    # Log filtered out casks
    echo "Name,Homepage" > "$log_file"
    jq -r "$@" "[.[] | select($filter_expr)] | .[] | [.token, .homepage] | @csv" "$input_file" >> "$log_file"

    # Filter: keep items where filter_expr is false
    # We use ( ... | not ) logic
    jq "$@" "[.[] | select(($filter_expr) | not)]" "$input_file" > "$output_file"
}

# Step 1: Download the Cask JSON
echo "Downloading casks from $URL..."
curl -s "$URL" -o "$INPUT_FILE"

# Print the total number of casks
total_count=$(jq length "$INPUT_FILE")
echo "Total casks available: $total_count"

INPUT_CSV="$OUTPUT_DIR/casks.csv"
echo "Name,Homepage" > "$INPUT_CSV"
jq -r ".[] | [.token, .homepage] | @csv" "$INPUT_FILE" >> "$INPUT_CSV"


# Step 2: Find and filter out disabled casks
run_filter_step "Disabled casks" \
    "$INPUT_FILE" \
    "$CASKS_STEP1" \
    "$LOG_DISABLED" \
    ".disabled"

# Step 3: Find and filter out deprecated casks
run_filter_step "Deprecated casks" \
    "$CASKS_STEP1" \
    "$CASKS_STEP2" \
    "$LOG_DEPRECATED" \
    ".deprecated"

# Step 4: Find and filter out variant casks (containing '@')
run_filter_step "Variant casks" \
    "$CASKS_STEP2" \
    "$CASKS_STEP3" \
    "$LOG_VARIANT" \
    ".token | contains(\"@\")"

# Step 5: Find and filter out casks that require Rosetta
run_filter_step "Casks requiring Rosetta" \
    "$CASKS_STEP3" \
    "$CASKS_STEP4" \
    "$LOG_ROSETTA" \
    ".caveats // \"\" | test(\"requires rosetta\"; \"i\")"

# Step 6: Find and filter out casks that include manual installers
run_filter_step "Manual installer casks" \
    "$CASKS_STEP4" \
    "$CASKS_STEP5" \
    "$LOG_MANUAL" \
    '[.artifacts[].installer?[]? | select(has("manual"))] | length > 0'

# Step 7: Find and filter out casks with "stage_only" artifacts
run_filter_step "Stage-only casks" \
    "$CASKS_STEP5" \
    "$CASKS_STEP6" \
    "$LOG_STAGE_ONLY" \
    ".artifacts | tostring | contains(\"stage_only\")"

# Step 8: Find and filter out casks without interesting artifacts
# Interesting artifacts: app, binary, installer, pkg, suite
# Logic: We remove items that do NOT match the interesting artifacts.
# The filter expression should be TRUE for items to REMOVE.
# So we want items where test(...) is FALSE.
run_filter_step "Casks without interesting artifacts" \
    "$CASKS_STEP6" \
    "$CASKS_FINAL" \
    "$LOG_NO_ARTIFACTS" \
    '.artifacts | tostring | test("\"(app|binary|installer|pkg|suite)\"") | not'

# Step 9: Filter out casks from custom ignore list (if provided)
ignore_file="$IGNORE_FILE"
: > "$ignore_file" # Create empty file

# Loop through arguments and append content to ignore_file
# Loop through arguments (patterns or files)
for pattern in "$@"; do
    # Expand glob patterns (even if quoted) using the ~ flag
    # (N) ensures it doesn't fail if no matches are found (NULL_GLOB)
    expanded_files=(${~pattern}(N))

    if (( ${#expanded_files} == 0 )); then
        echo "Warning: No files matched pattern '$pattern'. Skipping."
        continue
    fi

    for file in "${expanded_files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "Adding ignores from $file..."
            cat "$file" >> "$ignore_file"
        else
            echo "Warning: '$file' is not a regular file. Skipping."
        fi
    done
done

if [[ -s "$ignore_file" ]]; then
    # Convert text file to JSON array of strings
    # We use jq -R -s to read raw input as a single string,
    # then split by newlines and filter empty lines
    blacklist_json=$(jq -R -s 'split("\n") | map(select(length > 0))' \
        "$ignore_file")

    # Filter out casks present in blacklist
    run_filter_step "Custom ignored casks" \
        "$CASKS_FINAL" \
        "$CASKS_FINAL_CUSTOM" \
        "$LOG_CUSTOM" \
        '.token as $t | $blacklist | index($t)' \
        --argjson blacklist "$blacklist_json"
    mv "$CASKS_FINAL_CUSTOM" "$CASKS_FINAL"
else
    echo "No custom ignore list provided or empty."
    echo "Name,Homepage" > "$LOG_CUSTOM"
fi

# Final Output
final_count=$(jq length "$CASKS_FINAL")

# Generate CSV Output
echo "Name,Homepage" > "$OUTPUT_CSV"
jq -r '.[] | [.token, .homepage] | @csv' "$CASKS_FINAL" \
    >> "$OUTPUT_CSV"

# Generate Text Output
jq -r '.[].token' "$CASKS_FINAL" > "$OUTPUT_TXT"

echo "---------------------------------------------------"
echo "Final number of interesting casks: $final_count"
echo "Results saved to: $CASKS_FINAL," \
     "$OUTPUT_CSV, and $OUTPUT_TXT"

# Clean up temporary files
rm "$CASKS_STEP1" \
    "$CASKS_STEP2" \
    "$CASKS_STEP3" \
    "$CASKS_STEP4" \
    "$CASKS_STEP5" \
    "$CASKS_STEP6" \
    "$IGNORE_FILE"
# The result is in $CASKS_FINAL if you wish to inspect it,
# otherwise remove it too:
# rm "$CASKS_FINAL"
