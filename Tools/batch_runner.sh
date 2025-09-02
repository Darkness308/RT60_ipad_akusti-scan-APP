#!/usr/bin/env bash
# batch_runner.sh
# Batch processing tool for RT60 log files

set -euo pipefail

# Configuration
IN=${1:-"Tools/LogParser/fixtures"}
OUT=${2:-"Artifacts"}
TOOL_PATH=${3:-"./rt60log2json"}

echo "🚀 RT60 Batch Runner"
echo "Input directory: $IN"
echo "Output directory: $OUT"
echo "Tool path: $TOOL_PATH"

# Create output directory
mkdir -p "$OUT"

# Check if tool exists
if [[ ! -x "$TOOL_PATH" ]]; then
    echo "❌ Tool not found or not executable: $TOOL_PATH"
    echo "💡 Try building with: swift build -c release"
    exit 1
fi

# Check if input directory exists
if [[ ! -d "$IN" ]]; then
    echo "❌ Input directory not found: $IN"
    exit 1
fi

# Process all .txt files
processed=0
failed=0

echo "📁 Processing logs from $IN -> $OUT"

for f in "$IN"/*.txt; do
    if [[ ! -f "$f" ]]; then
        echo "⚠️  No .txt files found in $IN"
        continue
    fi
    
    base=$(basename "$f" .txt)
    output_file="$OUT/$base.audit.json"
    
    echo "🔄 Processing: $base"
    
    if "$TOOL_PATH" "$f" -o "$output_file"; then
        echo "✅ Success: $base -> $output_file"
        ((processed++))
    else
        echo "❌ Failed: $base"
        ((failed++))
    fi
done

echo ""
echo "📊 Summary:"
echo "  Processed: $processed files"
echo "  Failed: $failed files"
echo "  Output location: $OUT"

if [[ $failed -gt 0 ]]; then
    exit 1
fi

echo "🎉 Batch processing completed successfully!"