#!/bin/bash
# Venice.ai Image Generation Script
# Usage: generate.sh <output_path> <prompt> [model] [width] [height]

set -e

OUTPUT_PATH="$1"
PROMPT="$2"
MODEL="${3:-lustify-v7}"
WIDTH="${4:-1024}"
HEIGHT="${5:-1280}"

if [ -z "$OUTPUT_PATH" ] || [ -z "$PROMPT" ]; then
    echo "Error: Usage: generate.sh <output_path> <prompt> [model] [width] [height]" >&2
    exit 1
fi

if [ -z "$VENICE_API_KEY" ]; then
    echo "Error: VENICE_API_KEY environment variable not set" >&2
    exit 1
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT_PATH")"

# Make API request and capture response
RESPONSE=$(curl -s -w "\n%{http_code}" "https://api.venice.ai/api/v1/image/generate" \
    -H "Authorization: Bearer $VENICE_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"$MODEL\",
        \"prompt\": \"$PROMPT\",
        \"width\": $WIDTH,
        \"height\": $HEIGHT,
        \"format\": \"png\",
        \"cfg_scale\": 12.0,
        \"hide_watermark\": true
    }")

# Split response body and status code
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

# Check for HTTP errors
if [ "$HTTP_CODE" != "200" ]; then
    echo "Error: API returned HTTP $HTTP_CODE" >&2
    echo "$BODY" | jq -r '.error.message // .error // .' >&2
    exit 1
fi

# Check for API errors in response
ERROR=$(echo "$BODY" | jq -r '.error // empty')
if [ -n "$ERROR" ]; then
    echo "Error: $ERROR" >&2
    exit 1
fi

# Extract and decode image
# Venice API returns images in .images[] array (not .data[].b64_json)
B64_DATA=$(echo "$BODY" | jq -r '.images[0] // .data[0].b64_json // empty')
if [ -z "$B64_DATA" ]; then
    echo "Error: No image data in response" >&2
    echo "$BODY" | jq '.' >&2
    exit 1
fi

# Decode and save
echo "$B64_DATA" | base64 -d > "$OUTPUT_PATH"

# Verify output
if [ ! -s "$OUTPUT_PATH" ]; then
    echo "Error: Output file is empty" >&2
    exit 1
fi

FILE_SIZE=$(ls -lh "$OUTPUT_PATH" | awk '{print $5}')
echo "Success: Image saved to $OUTPUT_PATH ($FILE_SIZE)"
