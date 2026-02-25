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

# Hash verification
HASH_FILE="$ARTIFACTS_DIR/prompt_session.sha256"
if [ ! -f "$HASH_FILE" ]; then
  echo "  [FAIL] Hash file missing. Artifact immutability cannot be verified."
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  EXPECTED_HASH=$(cut -d ' ' -f 1 "$HASH_FILE")
  ACTUAL_HASH=$(shasum -a 256 "$ARTIFACT" | cut -d ' ' -f 1)
  if [ "$EXPECTED_HASH" = "$ACTUAL_HASH" ]; then
    echo "  [PASS] Artifact hash verified."
  else
    echo "  [FAIL] Artifact hash mismatch. Possible tampering detected."
    echo "    Expected: $EXPECTED_HASH"
    echo "    Actual:   $ACTUAL_HASH"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

# Chain integrity validation
if jq -e '.artifact_hash' "$ARTIFACT" > /dev/null 2>&1 && jq -e '.chain_hash' "$ARTIFACT" > /dev/null 2>&1; then
  STORED_ARTIFACT_HASH=$(jq -r '.artifact_hash' "$ARTIFACT")
  STORED_CHAIN_HASH=$(jq -r '.chain_hash' "$ARTIFACT")
  STORED_TIMESTAMP=$(jq -r '.timestamp_utc' "$ARTIFACT")

  # Recreate base JSON (without artifact_hash and chain_hash) and compute hash
  BASE_JSON=$(jq 'del(.artifact_hash, .chain_hash)' "$ARTIFACT")
  COMPUTED_ARTIFACT_HASH=$(printf '%s\n' "$BASE_JSON" | shasum -a 256 | cut -d ' ' -f 1)

  # Compute expected chain hash
  COMPUTED_CHAIN_HASH=$(printf '%s' "${STORED_ARTIFACT_HASH}${STORED_TIMESTAMP}" | shasum -a 256 | cut -d ' ' -f 1)

  if [ "$STORED_ARTIFACT_HASH" = "$COMPUTED_ARTIFACT_HASH" ] && [ "$STORED_CHAIN_HASH" = "$COMPUTED_CHAIN_HASH" ]; then
    echo "  [PASS] Chain integrity verified."
  else
    if [ "$STORED_ARTIFACT_HASH" != "$COMPUTED_ARTIFACT_HASH" ]; then
      echo "  [FAIL] Chain integrity violation — artifact_hash mismatch."
    fi
    if [ "$STORED_CHAIN_HASH" != "$COMPUTED_CHAIN_HASH" ]; then
      echo "  [FAIL] Chain integrity violation — chain_hash mismatch."
    fi
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
else
  echo "  [INFO] No chain fields present — skipping chain validation."
fi

# Policy version enforcement
POLICY_FILE="$(cd "$(dirname "$0")/.." && pwd)/policy/promptos_policy.json"
if [ -f "$POLICY_FILE" ] && command -v jq > /dev/null 2>&1; then
  REQUIRED_VERSION=$(jq -r '.required_promptos_version' "$POLICY_FILE")
  ARTIFACT_VERSION=$(jq -r '.prompt_os_version' "$ARTIFACT")
  if [ "$REQUIRED_VERSION" = "$ARTIFACT_VERSION" ]; then
    echo "  [PASS] PromptOS version matches policy."
  else
    echo "  [FAIL] PromptOS version mismatch."
    echo "    Required: $REQUIRED_VERSION"
    echo "    Found:    $ARTIFACT_VERSION"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi

  # Check chain validation requirement
  REQUIRE_CHAIN=$(jq -r '.require_chain_validation // false' "$POLICY_FILE")
  if [ "$REQUIRE_CHAIN" = "true" ]; then
    if ! jq -e '.artifact_hash' "$ARTIFACT" > /dev/null 2>&1 || ! jq -e '.chain_hash' "$ARTIFACT" > /dev/null 2>&1; then
      echo "  [FAIL] Policy requires chain validation but artifact lacks chain fields."
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  fi
else
  if [ ! -f "$POLICY_FILE" ]; then
    echo "  [INFO] No policy file found — skipping version enforcement."
  fi
fi

# PAS compiled hash verification (if pas block exists)
if jq -e '.pas' "$ARTIFACT" > /dev/null 2>&1; then
  echo ""
  echo "--- PAS Artifact Validation ---"
  PAS_COMPILED="$ARTIFACTS_DIR/pas_compiled.txt"
  STORED_PAS_HASH=$(jq -r '.pas.compiled_hash // ""' "$ARTIFACT")

  if [ -z "$STORED_PAS_HASH" ]; then
    echo "  [FAIL] pas block present but compiled_hash is missing."
    FAIL_COUNT=$((FAIL_COUNT + 1))
  elif [ ! -f "$PAS_COMPILED" ]; then
    echo "  [FAIL] pas block present but pas_compiled.txt not found in artifacts."
    FAIL_COUNT=$((FAIL_COUNT + 1))
  else
    COMPUTED_PAS_HASH=$(shasum -a 256 "$PAS_COMPILED" | cut -d ' ' -f 1)
    if [ "$STORED_PAS_HASH" = "$COMPUTED_PAS_HASH" ]; then
      echo "  [PASS] PAS compiled hash verified."
    else
      echo "  [FAIL] PAS compiled hash mismatch. Possible tampering."
      echo "    Expected: $STORED_PAS_HASH"
      echo "    Actual:   $COMPUTED_PAS_HASH"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  fi

  # Validate required pas sub-fields
  for pfield in stack_id stack_version compiled_hash; do
    if jq -e ".pas.${pfield}" "$ARTIFACT" > /dev/null 2>&1; then
      echo "  [PASS] pas.$pfield present"
    else
      echo "  [FAIL] pas.$pfield missing"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  done
fi

echo ""
if [ $FAIL_COUNT -eq 0 ]; then
  echo "[PASS] prompt_session.json validated."
  exit 0
else
  echo "[FAIL] prompt_session.json has $FAIL_COUNT validation error(s)."
  exit 1
fi
