#!/usr/bin/env bash
set -euo pipefail

ARTIFACTS_DIR=""

usage() {
  echo "Usage: $0 --artifacts-dir <path>"
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --artifacts-dir)
      ARTIFACTS_DIR="$2"
      shift 2
      ;;
    *)
      echo "[FAIL] Unknown argument: $1"
      usage
      ;;
  esac
done

if [ -z "$ARTIFACTS_DIR" ]; then
  echo "[FAIL] --artifacts-dir is required."
  usage
fi

ARTIFACT="$ARTIFACTS_DIR/prompt_session.json"

echo "=== PromptOS Artifact Validation ==="
echo ""

# Check file exists
if [ ! -f "$ARTIFACT" ]; then
  echo "[FAIL] prompt_session.json not found."
  echo "Governance requires a PromptOS session artifact."
  echo "  Expected: $ARTIFACT"
  exit 1
fi

echo "Found: $ARTIFACT"

# Check jq is available
if ! command -v jq > /dev/null 2>&1; then
  echo "[FAIL] jq is required for schema validation but not found."
  exit 1
fi

# Validate JSON is parseable
if ! jq empty "$ARTIFACT" 2>/dev/null; then
  echo "[FAIL] prompt_session.json is not valid JSON."
  exit 1
fi

# Validate required fields
FAIL_COUNT=0

REQUIRED_FIELDS="timestamp_utc prompt_os_version prompts_used developer target_repo lint_passed"
for field in $REQUIRED_FIELDS; do
  if jq -e ".${field}" "$ARTIFACT" > /dev/null 2>&1; then
    echo "  [PASS] Field present: $field"
  else
    echo "  [FAIL] Missing required field: $field"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done

# Validate field types
if jq -e '.prompts_used | type == "array"' "$ARTIFACT" > /dev/null 2>&1; then
  echo "  [PASS] prompts_used is an array"
else
  echo "  [FAIL] prompts_used must be an array"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if jq -e '.lint_passed | type == "boolean"' "$ARTIFACT" > /dev/null 2>&1; then
  echo "  [PASS] lint_passed is a boolean"
else
  echo "  [FAIL] lint_passed must be a boolean"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Validate timestamp format (basic pattern check)
TIMESTAMP=$(jq -r '.timestamp_utc // ""' "$ARTIFACT")
if echo "$TIMESTAMP" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'; then
  echo "  [PASS] timestamp_utc is ISO-8601 UTC format"
else
  echo "  [FAIL] timestamp_utc must be ISO-8601 UTC format (YYYY-MM-DDTHH:MM:SSZ)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""
if [ $FAIL_COUNT -eq 0 ]; then
  echo "[PASS] prompt_session.json validated."
  exit 0
else
  echo "[FAIL] prompt_session.json has $FAIL_COUNT validation error(s)."
  exit 1
fi
