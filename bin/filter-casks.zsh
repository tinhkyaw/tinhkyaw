#!/usr/bin/env zsh

# Define the API URL
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

# Step 1: Download the Cask JSON
echo "Downloading casks from $URL..."
curl -s "$URL" -o "$INPUT_FILE"

# Print the total number of casks
total_count=$(jq length "$INPUT_FILE")
echo "Total casks available: $total_count"

# Step 2: Find and filter out disabled casks
# logic: select(.disabled) finds disabled casks
disabled_count=$(jq '[.[] | select(.disabled)] | length' "$INPUT_FILE")
echo "Disabled casks found: $disabled_count"
# Log filtered out casks
# Log filtered out casks
jq -r '[.[] | select(.disabled)] | .[].token' "$INPUT_FILE" \
    > "$OUTPUT_DIR/casks_filtered_disabled.txt"
# Filter: keep only casks where .disabled is false or null
jq '[.[] | select(.disabled | not)]' "$INPUT_FILE" \
    > "$OUTPUT_DIR/casks_step1.json"

# Step 3: Find and filter out deprecated casks
# logic: select(.deprecated) finds deprecated casks
deprecated_count=$(jq '[.[] | select(.deprecated)] | length' "$OUTPUT_DIR/casks_step1.json")
echo "Deprecated casks found: $deprecated_count"
# Log filtered out casks
# Log filtered out casks
jq -r '[.[] | select(.deprecated)] | .[].token' "$OUTPUT_DIR/casks_step1.json" \
    > "$OUTPUT_DIR/casks_filtered_deprecated.txt"
# Filter: keep only casks where .deprecated is false or null
jq '[.[] | select(.deprecated | not)]' "$OUTPUT_DIR/casks_step1.json" \
    > "$OUTPUT_DIR/casks_step2.json"

# Step 4: Find and filter out casks that require Rosetta
# logic: check if "caveats" string contains "requires rosetta" (case insensitive)
rosetta_count=$(jq '[.[] | select(.caveats // "" | test("requires rosetta"; "i"))] | length' \
    "$OUTPUT_DIR/casks_step2.json")
echo "Casks requiring Rosetta found: $rosetta_count"
# Log filtered out casks
jq -r '[.[] | select(.caveats // "" | test("requires rosetta"; "i"))] | .[].token' \
    "$OUTPUT_DIR/casks_step2.json" > "$OUTPUT_DIR/casks_filtered_rosetta.txt"
# Filter: keep casks where caveats does NOT contain "requires rosetta"
jq '[.[] | select(.caveats // "" | test("requires rosetta"; "i") | not)]' \
    "$OUTPUT_DIR/casks_step2.json" > "$OUTPUT_DIR/casks_step3.json"

# Step 5: Find and filter out casks with "stage_only" artifacts
# logic: check if artifacts string contains "stage_only"
stage_only_count=$(jq '[.[] | select(.artifacts | tostring | contains("stage_only"))] | length' \
    "$OUTPUT_DIR/casks_step3.json")
echo "Stage-only casks found: $stage_only_count"
# Log filtered out casks
jq -r '[.[] | select(.artifacts | tostring | contains("stage_only"))] | .[].token' \
    "$OUTPUT_DIR/casks_step3.json" > "$OUTPUT_DIR/casks_filtered_stage_only.txt"
# Filter: keep casks where artifacts does NOT contain "stage_only"
jq '[.[] | select(.artifacts | tostring | contains("stage_only") | not)]' \
    "$OUTPUT_DIR/casks_step3.json" > "$OUTPUT_DIR/casks_step4.json"

# Step 6: Find and filter out casks without interesting artifacts
# Interesting artifacts: app, binary, installer, pkg, suite
# logic: Convert artifacts array to string and check if it does NOT match any of the interesting keys
no_artifact_count=$(jq \
    '[.[] | select(.artifacts | tostring | test("\"(app|binary|installer|pkg|suite)\"") | not)] | length' \
    "$OUTPUT_DIR/casks_step4.json")
echo "Casks without interesting artifacts found: $no_artifact_count"
# Log filtered out casks
jq -r \
    '[.[] | select(.artifacts | tostring | test("\"(app|binary|installer|pkg|suite)\"") | not)] | .[].token' \
    "$OUTPUT_DIR/casks_step4.json" > "$OUTPUT_DIR/casks_filtered_no_artifacts.txt"
# Filter: keep casks that DO contain interesting artifacts
jq '[.[] | select(.artifacts | tostring | test("\"(app|binary|installer|pkg|suite)\""))]' \
    "$OUTPUT_DIR/casks_step4.json" > "$OUTPUT_DIR/casks_final.json"

# Step 7: Filter out casks from custom ignore list (if provided)
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
    ignored_count=$(jq --argjson blacklist "$blacklist_json" \
        '[.[] | select(.token as $t | $blacklist | index($t))] | length' \
        "$OUTPUT_DIR/casks_final.json")
    echo "Custom ignored casks found: $ignored_count"

    # Log filtered out casks
    jq -r --argjson blacklist "$blacklist_json" \
        '[.[] | select(.token as $t | $blacklist | index($t))] | .[].token' \
        "$OUTPUT_DIR/casks_final.json" > "$OUTPUT_DIR/casks_filtered_custom.txt"

    # Perform the filter
    jq --argjson blacklist "$blacklist_json" \
        '[.[] | select(.token as $t | $blacklist | index($t) | not)]' \
        "$OUTPUT_DIR/casks_final.json" > "$OUTPUT_DIR/casks_final_custom.json"
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
rm "$INPUT_FILE" "$OUTPUT_DIR"/casks_step1.json "$OUTPUT_DIR"/casks_step2.json \
    "$OUTPUT_DIR"/casks_step3.json "$OUTPUT_DIR"/casks_step4.json "$ignore_file"
# The result is in $OUTPUT_DIR/casks_final.json if you wish to inspect it, otherwise remove it too:
# rm "$OUTPUT_DIR/casks_final.json"
