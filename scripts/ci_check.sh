#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINT_SCRIPT="$REPO_ROOT/scripts/lint_prompts.sh"
REGISTRY="$REPO_ROOT/prompts.index.json"
FAIL_COUNT=0

echo "=== Prompt OS CI Check ==="
echo ""

# Step 1: Run lint
echo "--- Step 1: Prompt Lint ---"
if "$LINT_SCRIPT"; then
  echo ""
else
  echo ""
  echo "[FAIL] Lint failed."
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Step 2: Validate registry exists and is valid JSON
echo "--- Step 2: Registry Validation ---"
if [ ! -f "$REGISTRY" ]; then
  echo "[FAIL] Registry not found: prompts.index.json"
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  # Check if it's valid JSON using python (available on macOS and most Linux)
  if python3 -c "import json; json.load(open('$REGISTRY'))" 2>/dev/null; then
    echo "[PASS] prompts.index.json is valid JSON"
  elif python -c "import json; json.load(open('$REGISTRY'))" 2>/dev/null; then
    echo "[PASS] prompts.index.json is valid JSON"
  else
    echo "[FAIL] prompts.index.json is not valid JSON"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi

  # Check required top-level keys
  for key in schema_version prompt_os_version prompts; do
    if grep -q "\"$key\"" "$REGISTRY"; then
      echo "[PASS] Registry contains key: $key"
    else
      echo "[FAIL] Registry missing key: $key"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  done
fi

# Step 3: Validate all registered prompt files exist
echo ""
echo "--- Step 3: Registry-to-File Check ---"
if [ -f "$REGISTRY" ]; then
  # Extract paths from registry using grep/sed (no jq dependency)
  PATHS=$(grep '"path"' "$REGISTRY" | sed 's/.*"path": *"\([^"]*\)".*/\1/')
  for filepath in $PATHS; do
    full_path="$REPO_ROOT/$filepath"
    if [ -f "$full_path" ]; then
      echo "[PASS] File exists: $filepath"
    else
      echo "[FAIL] File missing: $filepath"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  done
else
  echo "[FAIL] Cannot check files — registry not found."
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Step 4: Prompt Artifact Enforcement (optional)
echo "--- Step 4: Prompt Artifact Enforcement ---"
if [ -n "${PROMPTOS_ARTIFACTS_DIR:-}" ]; then
  VALIDATE_SCRIPT="$REPO_ROOT/scripts/validate_prompt_artifact.sh"
  if [ -x "$VALIDATE_SCRIPT" ]; then
    if "$VALIDATE_SCRIPT" --artifacts-dir "$PROMPTOS_ARTIFACTS_DIR"; then
      echo ""
    else
      echo ""
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  else
    echo "[FAIL] validate_prompt_artifact.sh not found or not executable"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
else
  echo "[INFO] Skipping artifact validation (PROMPTOS_ARTIFACTS_DIR not set)"
fi
echo ""

# Step 5: Example script guard
echo "--- Step 5: Example Script Guard ---"
EXAMPLE_SCRIPT="$REPO_ROOT/examples/first-governed-run/run.sh"
if [ ! -f "$EXAMPLE_SCRIPT" ]; then
  echo "[FAIL] Example script missing: examples/first-governed-run/run.sh"
  FAIL_COUNT=$((FAIL_COUNT + 1))
elif [ ! -x "$EXAMPLE_SCRIPT" ]; then
  echo "[FAIL] Example script not executable: examples/first-governed-run/run.sh"
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  echo "[PASS] Example script exists and is executable"
  # Verify it references real repo commands
  MISSING_REF=0
  for ref in "bin/promptos" "session/export_session_artifact.sh" "scripts/validate_prompt_artifact.sh" "integration/drift_lock_check.sh"; do
    if grep -q "$ref" "$EXAMPLE_SCRIPT"; then
      echo "[PASS] References: $ref"
    else
      echo "[FAIL] Missing reference to: $ref"
      MISSING_REF=1
    fi
  done
  if [ $MISSING_REF -ne 0 ]; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi
echo ""

# Summary
echo ""
echo "=== CI Check Summary ==="
if [ $FAIL_COUNT -eq 0 ]; then
  echo "[PASS] All CI checks passed."
  exit 0
else
  echo "[FAIL] $FAIL_COUNT issue(s) found."
  exit 1
fi
