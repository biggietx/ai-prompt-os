#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIFF_SCRIPT="$REPO_ROOT/scripts/pas_diff.sh"
FAIL_COUNT=0

echo "=== PAS Diff Tests ==="
echo ""

# --- Test 1: JSON output is valid ---
echo "--- Test 1: JSON output validity ---"
DIFF_OUTPUT=$("$DIFF_SCRIPT" --from STACK-GLOBAL-BASE-001 --to STACK-GLOBAL-BASE-002 --format json 2>/dev/null)
if echo "$DIFF_OUTPUT" | jq empty 2>/dev/null; then
  echo "  [PASS] JSON output is valid"
else
  echo "  [FAIL] JSON output is not valid"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- Test 2: Added module detected ---
echo "--- Test 2: Added module detection ---"
if echo "$DIFF_OUTPUT" | jq -e '.added_modules | index("pref-verbose-explanations-910") != null' > /dev/null 2>&1; then
  echo "  [PASS] pref-verbose-explanations-910 in added_modules"
else
  echo "  [FAIL] pref-verbose-explanations-910 not found in added_modules"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- Test 3: Removed module detected ---
echo "--- Test 3: Removed module detection ---"
if echo "$DIFF_OUTPUT" | jq -e '.removed_modules | index("output-concise-bullets-240") != null' > /dev/null 2>&1; then
  echo "  [PASS] output-concise-bullets-240 in removed_modules"
else
  echo "  [FAIL] output-concise-bullets-240 not found in removed_modules"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- Test 4: Common modules correct count ---
echo "--- Test 4: Common modules count ---"
COMMON_COUNT=$(echo "$DIFF_OUTPUT" | jq '.common_modules | length')
if [ "$COMMON_COUNT" -eq 5 ]; then
  echo "  [PASS] 5 common modules"
else
  echo "  [FAIL] Expected 5 common modules, got $COMMON_COUNT"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- Test 5: Metadata version change detected ---
echo "--- Test 5: Metadata version change ---"
if echo "$DIFF_OUTPUT" | jq -e '.metadata_changes.version.from == "1.0.0" and .metadata_changes.version.to == "1.1.0"' > /dev/null 2>&1; then
  echo "  [PASS] Version change 1.0.0 → 1.1.0 detected"
else
  echo "  [FAIL] Version metadata change not detected"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- Test 6: Markdown output produces content ---
echo "--- Test 6: Markdown output ---"
MD_OUTPUT=$("$DIFF_SCRIPT" --from STACK-GLOBAL-BASE-001 --to STACK-GLOBAL-BASE-002 --format md 2>/dev/null)
if echo "$MD_OUTPUT" | grep -q "Added Modules" && echo "$MD_OUTPUT" | grep -q "Removed Modules"; then
  echo "  [PASS] Markdown output contains expected sections"
else
  echo "  [FAIL] Markdown output missing expected sections"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- Test 7: Self-diff produces no changes ---
echo "--- Test 7: Self-diff (no changes) ---"
SELF_DIFF=$("$DIFF_SCRIPT" --from STACK-GLOBAL-BASE-001 --to STACK-GLOBAL-BASE-001 --format json 2>/dev/null)
SELF_ADDED=$(echo "$SELF_DIFF" | jq '.added_modules | length')
SELF_REMOVED=$(echo "$SELF_DIFF" | jq '.removed_modules | length')
SELF_CHANGED=$(echo "$SELF_DIFF" | jq '.changed_modules | length')
if [ "$SELF_ADDED" -eq 0 ] && [ "$SELF_REMOVED" -eq 0 ] && [ "$SELF_CHANGED" -eq 0 ]; then
  echo "  [PASS] Self-diff produces no changes"
else
  echo "  [FAIL] Self-diff should produce no changes"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- Summary ---
echo ""
echo "=== PAS Diff Test Summary ==="
if [ $FAIL_COUNT -eq 0 ]; then
  echo "[PASS] All diff tests passed."
  exit 0
else
  echo "[FAIL] $FAIL_COUNT test(s) failed."
  exit 1
fi
