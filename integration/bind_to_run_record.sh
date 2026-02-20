#!/usr/bin/env bash
set -euo pipefail

RUN_RECORD=""
PROMPT_ARTIFACT=""

usage() {
  echo "Usage: $0 --run-record <run_record.json> --prompt-artifact <prompt_session.json>"
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --run-record)
      RUN_RECORD="$2"
      shift 2
      ;;
    --prompt-artifact)
      PROMPT_ARTIFACT="$2"
      shift 2
      ;;
    *)
      echo "[FAIL] Unknown argument: $1"
      usage
      ;;
  esac
done

if [ -z "$RUN_RECORD" ] || [ -z "$PROMPT_ARTIFACT" ]; then
  echo "[FAIL] Both --run-record and --prompt-artifact are required."
  usage
fi

if [ ! -f "$RUN_RECORD" ]; then
  echo "[FAIL] Run record not found: $RUN_RECORD"
  exit 1
fi

if [ ! -f "$PROMPT_ARTIFACT" ]; then
  echo "[FAIL] Prompt artifact not found: $PROMPT_ARTIFACT"
  exit 1
fi

if ! command -v jq > /dev/null 2>&1; then
  echo "[FAIL] jq is required but not found."
  exit 1
fi

# Check if governance key already exists
if jq -e '.governance' "$RUN_RECORD" > /dev/null 2>&1; then
  echo "[FAIL] Run record already contains a 'governance' key. Binding rejected to prevent overwrite."
  exit 1
fi

# Extract hashes from prompt artifact
ARTIFACT_HASH=$(jq -r '.artifact_hash // empty' "$PROMPT_ARTIFACT")
CHAIN_HASH=$(jq -r '.chain_hash // empty' "$PROMPT_ARTIFACT")

if [ -z "$ARTIFACT_HASH" ] || [ -z "$CHAIN_HASH" ]; then
  echo "[FAIL] Prompt artifact missing artifact_hash or chain_hash."
  exit 1
fi

# Bind governance data to run record
UPDATED=$(jq --arg ah "$ARTIFACT_HASH" --arg ch "$CHAIN_HASH" \
  '.governance = {"prompt_artifact_hash": $ah, "prompt_chain_hash": $ch}' \
  "$RUN_RECORD")

echo "$UPDATED" > "$RUN_RECORD"

echo "[PASS] Governance bound to run record."
echo "  prompt_artifact_hash: $ARTIFACT_HASH"
echo "  prompt_chain_hash:    $CHAIN_HASH"
echo "  Run record:           $RUN_RECORD"
