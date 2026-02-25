#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PAS_DIR="$REPO_ROOT/pas"
MODULES_DIR="$PAS_DIR/modules"
STACKS_DIR="$PAS_DIR/stacks"
FAIL_COUNT=0

echo "=== PAS Lint ==="
echo ""

# Check jq availability
if ! command -v jq > /dev/null 2>&1; then
  echo "[FAIL] jq is required for PAS validation."
  exit 1
fi

# --- Module Validation ---

echo "--- Modules ---"
MODULE_FILES=$(find "$MODULES_DIR" -name '*.json' -type f 2>/dev/null | sort)

if [ -z "$MODULE_FILES" ]; then
  echo "[INFO] No modules found — skipping module validation."
else
  MODULE_IDS=()

  for mfile in $MODULE_FILES; do
    rel_path="${mfile#"$REPO_ROOT/"}"

    # Valid JSON
    if ! jq empty "$mfile" 2>/dev/null; then
      echo "  [FAIL] $rel_path — invalid JSON"
      FAIL_COUNT=$((FAIL_COUNT + 1))
      continue
    fi

    # Required fields
    MISSING=0
    for field in id type category dewey version status tags content; do
      if ! jq -e "has(\"$field\")" "$mfile" > /dev/null 2>&1; then
        echo "  [FAIL] $rel_path — missing required field: $field"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        MISSING=1
      fi
    done
    if [ $MISSING -ne 0 ]; then
      continue
    fi

    # Type must be "module"
    TYPE_VAL=$(jq -r '.type' "$mfile")
    if [ "$TYPE_VAL" != "module" ]; then
      echo "  [FAIL] $rel_path — type must be \"module\", found \"$TYPE_VAL\""
      FAIL_COUNT=$((FAIL_COUNT + 1))
      continue
    fi

    # Status must be draft or approved
    STATUS_VAL=$(jq -r '.status' "$mfile")
    if [ "$STATUS_VAL" != "draft" ] && [ "$STATUS_VAL" != "approved" ]; then
      echo "  [FAIL] $rel_path — status must be \"draft\" or \"approved\", found \"$STATUS_VAL\""
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    # Tags must be array
    if ! jq -e '.tags | type == "array"' "$mfile" > /dev/null 2>&1; then
      echo "  [FAIL] $rel_path — tags must be an array"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    # Collect ID for duplicate check
    MOD_ID=$(jq -r '.id' "$mfile")
    MODULE_IDS+=("$MOD_ID")

    echo "  [PASS] $rel_path — id: $MOD_ID"
  done

  # Duplicate ID check
  echo ""
  echo "--- Duplicate ID Check ---"
  SEEN_IDS=()
  for mid in "${MODULE_IDS[@]}"; do
    for seen in "${SEEN_IDS[@]+"${SEEN_IDS[@]}"}"; do
      if [ "$mid" = "$seen" ]; then
        echo "  [FAIL] Duplicate module ID: $mid"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    done
    SEEN_IDS+=("$mid")
  done
  if [ $FAIL_COUNT -eq 0 ]; then
    echo "  [PASS] No duplicate module IDs"
  fi
fi
echo ""

# --- Stack Validation ---

echo "--- Stacks ---"
STACK_FILES=$(find "$STACKS_DIR" -name '*.json' -type f 2>/dev/null | sort)

if [ -z "$STACK_FILES" ]; then
  echo "[INFO] No stacks found — skipping stack validation."
else
  for sfile in $STACK_FILES; do
    rel_path="${sfile#"$REPO_ROOT/"}"

    # Valid JSON
    if ! jq empty "$sfile" 2>/dev/null; then
      echo "  [FAIL] $rel_path — invalid JSON"
      FAIL_COUNT=$((FAIL_COUNT + 1))
      continue
    fi

    # Required fields
    MISSING=0
    for field in id type version status includes; do
      if ! jq -e "has(\"$field\")" "$sfile" > /dev/null 2>&1; then
        echo "  [FAIL] $rel_path — missing required field: $field"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        MISSING=1
      fi
    done
    if [ $MISSING -ne 0 ]; then
      continue
    fi

    # Type must be "stack"
    TYPE_VAL=$(jq -r '.type' "$sfile")
    if [ "$TYPE_VAL" != "stack" ]; then
      echo "  [FAIL] $rel_path — type must be \"stack\", found \"$TYPE_VAL\""
      FAIL_COUNT=$((FAIL_COUNT + 1))
      continue
    fi

    # Status must be draft or approved
    STATUS_VAL=$(jq -r '.status' "$sfile")
    if [ "$STATUS_VAL" != "draft" ] && [ "$STATUS_VAL" != "approved" ]; then
      echo "  [FAIL] $rel_path — status must be \"draft\" or \"approved\", found \"$STATUS_VAL\""
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    # Includes must be array
    if ! jq -e '.includes | type == "array"' "$sfile" > /dev/null 2>&1; then
      echo "  [FAIL] $rel_path — includes must be an array"
      FAIL_COUNT=$((FAIL_COUNT + 1))
      continue
    fi

    # Verify each included module ID exists in a module file
    INCLUDES=$(jq -r '.includes[]' "$sfile" 2>/dev/null)
    for inc_id in $INCLUDES; do
      FOUND=0
      if [ -n "${MODULE_FILES:-}" ]; then
        for mfile in $MODULE_FILES; do
          MID=$(jq -r '.id' "$mfile" 2>/dev/null)
          if [ "$MID" = "$inc_id" ]; then
            FOUND=1
            break
          fi
        done
      fi
      if [ $FOUND -eq 0 ]; then
        echo "  [FAIL] $rel_path — includes module \"$inc_id\" which does not exist"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    done

    STACK_ID=$(jq -r '.id' "$sfile")
    echo "  [PASS] $rel_path — id: $STACK_ID"
  done
fi
echo ""

# --- Module Registry Enforcement ---

MODULES_REGISTRY="$PAS_DIR/registry/modules.index.json"
echo "--- Module Registry Enforcement ---"
if [ ! -f "$MODULES_REGISTRY" ]; then
  echo "  [FAIL] modules.index.json not found"
  FAIL_COUNT=$((FAIL_COUNT + 1))
elif ! jq empty "$MODULES_REGISTRY" 2>/dev/null; then
  echo "  [FAIL] modules.index.json is not valid JSON"
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  # Every module file must be listed in registry
  if [ -n "${MODULE_FILES:-}" ]; then
    for mfile in $MODULE_FILES; do
      rel_path="${mfile#"$REPO_ROOT/"}"
      if ! jq -e --arg p "$rel_path" 'map(.path) | index($p) != null' "$MODULES_REGISTRY" > /dev/null 2>&1; then
        echo "  [FAIL] Module file not in registry: $rel_path"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    done
  fi

  # Every registry entry must point to an existing file
  REG_PATHS=$(jq -r '.[].path' "$MODULES_REGISTRY" 2>/dev/null)
  for rpath in $REG_PATHS; do
    if [ ! -f "$REPO_ROOT/$rpath" ]; then
      echo "  [FAIL] Registry entry points to missing file: $rpath"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  done

  # Registry IDs must match file IDs
  REG_ENTRIES=$(jq -c '.[]' "$MODULES_REGISTRY" 2>/dev/null)
  while IFS= read -r entry; do
    reg_id=$(echo "$entry" | jq -r '.id')
    reg_path=$(echo "$entry" | jq -r '.path')
    if [ -f "$REPO_ROOT/$reg_path" ]; then
      file_id=$(jq -r '.id' "$REPO_ROOT/$reg_path" 2>/dev/null)
      if [ "$reg_id" != "$file_id" ]; then
        echo "  [FAIL] Registry ID mismatch: registry says \"$reg_id\", file says \"$file_id\" ($reg_path)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    fi
  done <<< "$REG_ENTRIES"

  if [ $FAIL_COUNT -eq 0 ] || echo "" > /dev/null; then
    # Count checks that passed in this section
    echo "  [PASS] Module registry consistent"
  fi
fi
echo ""

# --- Stack Registry Enforcement ---

STACKS_REGISTRY="$PAS_DIR/registry/stacks.index.json"
echo "--- Stack Registry Enforcement ---"
if [ ! -f "$STACKS_REGISTRY" ]; then
  echo "  [FAIL] stacks.index.json not found"
  FAIL_COUNT=$((FAIL_COUNT + 1))
elif ! jq empty "$STACKS_REGISTRY" 2>/dev/null; then
  echo "  [FAIL] stacks.index.json is not valid JSON"
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  # Every stack file must be listed in registry
  if [ -n "${STACK_FILES:-}" ]; then
    for sfile in $STACK_FILES; do
      rel_path="${sfile#"$REPO_ROOT/"}"
      if ! jq -e --arg p "$rel_path" 'map(.path) | index($p) != null' "$STACKS_REGISTRY" > /dev/null 2>&1; then
        echo "  [FAIL] Stack file not in registry: $rel_path"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    done
  fi

  # Every registry entry must point to an existing file
  REG_PATHS=$(jq -r '.[].path' "$STACKS_REGISTRY" 2>/dev/null)
  for rpath in $REG_PATHS; do
    if [ ! -f "$REPO_ROOT/$rpath" ]; then
      echo "  [FAIL] Registry entry points to missing file: $rpath"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  done

  # Registry IDs must match file IDs
  REG_ENTRIES=$(jq -c '.[]' "$STACKS_REGISTRY" 2>/dev/null)
  while IFS= read -r entry; do
    reg_id=$(echo "$entry" | jq -r '.id')
    reg_path=$(echo "$entry" | jq -r '.path')
    if [ -f "$REPO_ROOT/$reg_path" ]; then
      file_id=$(jq -r '.id' "$REPO_ROOT/$reg_path" 2>/dev/null)
      if [ "$reg_id" != "$file_id" ]; then
        echo "  [FAIL] Registry ID mismatch: registry says \"$reg_id\", file says \"$file_id\" ($reg_path)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
    fi
  done <<< "$REG_ENTRIES"

  echo "  [PASS] Stack registry consistent"
fi
echo ""

# --- Summary ---

echo "=== PAS Lint Summary ==="
if [ $FAIL_COUNT -eq 0 ]; then
  echo "[PASS] All PAS checks passed."
  exit 0
else
  echo "[FAIL] $FAIL_COUNT issue(s) found."
  exit 1
fi
