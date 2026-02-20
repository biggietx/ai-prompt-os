#!/usr/bin/env bash
set -euo pipefail

ARTIFACT_DIR=""

usage() {
  echo "Usage: $0 --artifact-dir <path>"
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --artifact-dir)
      ARTIFACT_DIR="$2"
      shift 2
      ;;
    *)
      echo "[FAIL] Unknown argument: $1"
      usage
      ;;
  esac
done

if [ -z "$ARTIFACT_DIR" ]; then
  echo "[FAIL] --artifact-dir is required."
  usage
fi

ARTIFACT="$ARTIFACT_DIR/prompt_session.json"
HASH_FILE="$ARTIFACT_DIR/prompt_session.sha256"
FAIL_COUNT=0

echo "=== Drift Lock Check ==="
echo ""

# 1. Check prompt_session.json exists
if [ ! -f "$ARTIFACT" ]; then
  echo "[FAIL] prompt_session.json not found."
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  echo "[PASS] prompt_session.json exists."
fi

# 2. Check .sha256 exists
if [ ! -f "$HASH_FILE" ]; then
  echo "[FAIL] prompt_session.sha256 not found."
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  echo "[PASS] prompt_session.sha256 exists."
fi

# Only proceed with hash checks if both files exist
if [ -f "$ARTIFACT" ] && [ -f "$HASH_FILE" ]; then

  # 3. Verify sidecar hash
  EXPECTED_HASH=$(cut -d ' ' -f 1 "$HASH_FILE")
  ACTUAL_HASH=$(shasum -a 256 "$ARTIFACT" | cut -d ' ' -f 1)
  if [ "$EXPECTED_HASH" = "$ACTUAL_HASH" ]; then
    echo "[PASS] Sidecar hash verified."
  else
    echo "[FAIL] Sidecar hash mismatch."
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi

  # 4. Verify artifact_hash (if present)
  if command -v jq > /dev/null 2>&1; then
    if jq -e '.artifact_hash' "$ARTIFACT" > /dev/null 2>&1; then
      STORED_ARTIFACT_HASH=$(jq -r '.artifact_hash' "$ARTIFACT")
      BASE_JSON=$(jq 'del(.artifact_hash, .chain_hash)' "$ARTIFACT")
      COMPUTED_ARTIFACT_HASH=$(printf '%s\n' "$BASE_JSON" | shasum -a 256 | cut -d ' ' -f 1)
      if [ "$STORED_ARTIFACT_HASH" = "$COMPUTED_ARTIFACT_HASH" ]; then
        echo "[PASS] artifact_hash valid."
      else
        echo "[FAIL] artifact_hash invalid."
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      echo "[INFO] No artifact_hash field — skipping."
    fi

    # 5. Verify chain_hash (if present)
    if jq -e '.chain_hash' "$ARTIFACT" > /dev/null 2>&1; then
      STORED_CHAIN_HASH=$(jq -r '.chain_hash' "$ARTIFACT")
      STORED_ARTIFACT_HASH=$(jq -r '.artifact_hash' "$ARTIFACT")
      STORED_TIMESTAMP=$(jq -r '.timestamp_utc' "$ARTIFACT")
      COMPUTED_CHAIN_HASH=$(printf '%s' "${STORED_ARTIFACT_HASH}${STORED_TIMESTAMP}" | shasum -a 256 | cut -d ' ' -f 1)
      if [ "$STORED_CHAIN_HASH" = "$COMPUTED_CHAIN_HASH" ]; then
        echo "[PASS] chain_hash valid."
      else
        echo "[FAIL] chain_hash invalid."
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    else
      echo "[INFO] No chain_hash field — skipping."
    fi
  else
    echo "[INFO] jq not available — skipping chain field checks."
  fi
fi

echo ""
if [ $FAIL_COUNT -eq 0 ]; then
  echo "[DRIFT LOCKED] Artifact integrity intact."
  exit 0
else
  echo "[DRIFT DETECTED] Governance artifact invalid."
  exit 1
fi
