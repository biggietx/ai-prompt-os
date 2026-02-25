#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
POLICY="$REPO_ROOT/policy/promptos_policy.json"
REGISTRY="$REPO_ROOT/prompts.index.json"
PROMPTS_DIR="$REPO_ROOT/prompts"
FAIL_COUNT=0

echo "=== Version Consistency Check ==="
echo ""

# A. Get latest git tag
LATEST_TAG=$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$LATEST_TAG" ]; then
  echo "[FAIL] No git tag found. Cannot verify version consistency."
  exit 1
fi

# B. Strip leading "v" for numeric comparison
NUMERIC_VERSION="${LATEST_TAG#v}"

echo "Git tag:         $LATEST_TAG"
echo "Numeric version: $NUMERIC_VERSION"
echo ""

# C. Extract versions from each source

# Policy version
if [ ! -f "$POLICY" ]; then
  echo "[FAIL] Policy file not found: policy/promptos_policy.json"
  exit 1
fi
POLICY_VERSION=$(grep '"required_promptos_version"' "$POLICY" | sed 's/.*: *"\([^"]*\)".*/\1/')

# Registry version
if [ ! -f "$REGISTRY" ]; then
  echo "[FAIL] Registry file not found: prompts.index.json"
  exit 1
fi
REGISTRY_VERSION=$(grep '"prompt_os_version"' "$REGISTRY" | sed 's/.*: *"\([^"]*\)".*/\1/')

echo "--- Source Versions ---"
echo "  Policy (required_promptos_version): $POLICY_VERSION"
echo "  Registry (prompt_os_version):       $REGISTRY_VERSION"

# D. Validate policy matches LATEST_TAG exactly
echo ""
echo "--- Validation ---"

if [ "$POLICY_VERSION" = "$LATEST_TAG" ]; then
  echo "[PASS] Policy version matches git tag ($POLICY_VERSION = $LATEST_TAG)"
else
  echo "[FAIL] Policy version mismatch: expected $LATEST_TAG, found $POLICY_VERSION"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Registry must match LATEST_TAG (allow optional leading v but enforce consistency)
REGISTRY_NUMERIC="${REGISTRY_VERSION#v}"
if [ "$REGISTRY_NUMERIC" = "$NUMERIC_VERSION" ]; then
  echo "[PASS] Registry version matches git tag ($REGISTRY_VERSION ~ $LATEST_TAG)"
else
  echo "[FAIL] Registry version mismatch: expected $LATEST_TAG (or $NUMERIC_VERSION), found $REGISTRY_VERSION"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# All prompt YAML version fields must match numeric portion of LATEST_TAG
echo ""
echo "--- Prompt YAML Headers ---"
PROMPT_FILES=$(find "$PROMPTS_DIR" -name '*.md' -type f | sort)

if [ -z "$PROMPT_FILES" ]; then
  echo "[FAIL] No prompt files found in prompts/"
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  for pfile in $PROMPT_FILES; do
    rel_path="${pfile#"$REPO_ROOT/"}"
    # Extract version from YAML header (between --- delimiters)
    YAML_VERSION=$(awk '/^---$/{n++; next} n==1 && /^version:/{gsub(/^version: */, ""); gsub(/ *$/, ""); print}' "$pfile")

    if [ -z "$YAML_VERSION" ]; then
      echo "[FAIL] $rel_path — no version field in YAML header"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    elif [ "$YAML_VERSION" = "$NUMERIC_VERSION" ]; then
      echo "[PASS] $rel_path — version $YAML_VERSION"
    else
      echo "[FAIL] $rel_path — expected $NUMERIC_VERSION, found $YAML_VERSION"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  done
fi

# E/F. Summary
echo ""
echo "=== Version Consistency Summary ==="
if [ $FAIL_COUNT -eq 0 ]; then
  echo "[PASS] All version strings consistent with $LATEST_TAG"
  exit 0
else
  echo "[FAIL] $FAIL_COUNT version mismatch(es) found."
  exit 1
fi
