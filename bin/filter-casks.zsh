#!/usr/bin/env zsh

# Define the API URL
URL="https://formulae.brew.sh/api/cask.json"
OUTPUT_DIR="${OUTPUT_DIR:-.casks}"
mkdir -p "$OUTPUT_DIR"
INPUT_FILE="$OUTPUT_DIR/casks.json"

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
    jq -r "$@" "[.[] | select($filter_expr)] | .[].token" "$input_file" > "$log_file"

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

# Step 2: Find and filter out disabled casks
run_filter_step "Disabled casks" \
    "$INPUT_FILE" \
    "$OUTPUT_DIR/casks_step1.json" \
    "$OUTPUT_DIR/casks_filtered_disabled.txt" \
    ".disabled"

# Step 3: Find and filter out deprecated casks
run_filter_step "Deprecated casks" \
    "$OUTPUT_DIR/casks_step1.json" \
    "$OUTPUT_DIR/casks_step2.json" \
    "$OUTPUT_DIR/casks_filtered_deprecated.txt" \
    ".deprecated"

# Step 4: Find and filter out variant casks (containing '@')
run_filter_step "Variant casks" \
    "$OUTPUT_DIR/casks_step2.json" \
    "$OUTPUT_DIR/casks_step3.json" \
    "$OUTPUT_DIR/casks_filtered_variant.txt" \
    ".token | contains(\"@\")"

# Step 5: Find and filter out casks that require Rosetta
run_filter_step "Casks requiring Rosetta" \
    "$OUTPUT_DIR/casks_step3.json" \
    "$OUTPUT_DIR/casks_step4.json" \
    "$OUTPUT_DIR/casks_filtered_rosetta.txt" \
    ".caveats // \"\" | test(\"requires rosetta\"; \"i\")"

# Step 6: Find and filter out casks that include manual installers
run_filter_step "Manual installer casks" \
    "$OUTPUT_DIR/casks_step4.json" \
    "$OUTPUT_DIR/casks_step5.json" \
    "$OUTPUT_DIR/casks_filtered_manual.txt" \
    '[.artifacts[].installer?[]? | select(has("manual"))] | length > 0'

# Step 7: Find and filter out casks with "stage_only" artifacts
run_filter_step "Stage-only casks" \
    "$OUTPUT_DIR/casks_step5.json" \
    "$OUTPUT_DIR/casks_step6.json" \
    "$OUTPUT_DIR/casks_filtered_stage_only.txt" \
    ".artifacts | tostring | contains(\"stage_only\")"

# Step 8: Find and filter out casks without interesting artifacts
# Interesting artifacts: app, binary, installer, pkg, suite
# Logic: We remove items that do NOT match the interesting artifacts.
# The filter expression should be TRUE for items to REMOVE.
# So we want items where test(...) is FALSE.
run_filter_step "Casks without interesting artifacts" \
    "$OUTPUT_DIR/casks_step6.json" \
    "$OUTPUT_DIR/casks_final.json" \
    "$OUTPUT_DIR/casks_filtered_no_artifacts.txt" \
    '.artifacts | tostring | test("\"(app|binary|installer|pkg|suite)\"") | not'

# Step 9: Filter out casks from custom ignore list (if provided)
ignore_file="$OUTPUT_DIR/casks_to_ignore.txt"
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
        "$OUTPUT_DIR/casks_final.json" \
        "$OUTPUT_DIR/casks_final_custom.json" \
        "$OUTPUT_DIR/casks_filtered_custom.txt" \
        '.token as $t | $blacklist | index($t)' \
        --argjson blacklist "$blacklist_json"
    mv "$OUTPUT_DIR/casks_final_custom.json" "$OUTPUT_DIR/casks_final.json"
else
    echo "No custom ignore list provided or empty."
    echo "0" > "$OUTPUT_DIR/casks_filtered_custom.txt"
fi

# Final Output
final_count=$(jq length "$OUTPUT_DIR/casks_final.json")

# Generate CSV Output
echo "Name,Homepage" > "$OUTPUT_DIR/casks_final.csv"
jq -r '.[] | [.token, .homepage] | @csv' "$OUTPUT_DIR/casks_final.json" \
    >> "$OUTPUT_DIR/casks_final.csv"

# Generate Text Output
jq -r '.[].token' "$OUTPUT_DIR/casks_final.json" > "$OUTPUT_DIR/casks_final.txt"

echo "---------------------------------------------------"
echo "Final number of interesting casks: $final_count"
echo "Results saved to: $OUTPUT_DIR/casks_final.json," \
     "$OUTPUT_DIR/casks_final.csv, and $OUTPUT_DIR/casks_final.txt"

# Clean up temporary files
rm "$INPUT_FILE" "$OUTPUT_DIR"/casks_step1.json \
    "$OUTPUT_DIR"/casks_step2.json "$OUTPUT_DIR"/casks_step3.json \
    "$OUTPUT_DIR"/casks_step4.json "$OUTPUT_DIR"/casks_step5.json \
    "$OUTPUT_DIR"/casks_step6.json \
    "$ignore_file"
# The result is in $OUTPUT_DIR/casks_final.json if you wish to inspect it,
# otherwise remove it too:
# rm "$OUTPUT_DIR/casks_final.json"
