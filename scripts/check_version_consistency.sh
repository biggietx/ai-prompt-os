#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
POLICY="$REPO_ROOT/policy/promptos_policy.json"
REGISTRY="$REPO_ROOT/prompts.index.json"
PROMPTS_DIR="$REPO_ROOT/prompts"

echo "=== Version Consistency Check ==="
echo ""

# --- Helpers ---

# Parse "major.minor.patch" from a version string, stripping optional leading "v"
parse_semver() {
  local ver="${1#v}"
  local major minor patch
  major=$(echo "$ver" | cut -d. -f1)
  minor=$(echo "$ver" | cut -d. -f2)
  patch=$(echo "$ver" | cut -d. -f3)
  echo "$major $minor $patch"
}

# Compute the next valid patch version from a semver string
next_patch() {
  local major minor patch
  read -r major minor patch <<< "$(parse_semver "$1")"
  echo "$major.$minor.$((patch + 1))"
}

# --- A. Get latest git tag ---

LATEST_TAG=$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$LATEST_TAG" ]; then
  echo "[FAIL] No git tag found. Cannot verify version consistency."
  exit 1
fi

TAG_NUMERIC="${LATEST_TAG#v}"
NEXT_PATCH=$(next_patch "$TAG_NUMERIC")

echo "Git tag:            $LATEST_TAG"
echo "Tag numeric:        $TAG_NUMERIC"
echo "Next valid patch:   $NEXT_PATCH"
echo ""

# --- B. Extract versions from each source ---

if [ ! -f "$POLICY" ]; then
  echo "[FAIL] Policy file not found: policy/promptos_policy.json"
  exit 1
fi
POLICY_VERSION=$(grep '"required_promptos_version"' "$POLICY" | sed 's/.*: *"\([^"]*\)".*/\1/')
POLICY_NUMERIC="${POLICY_VERSION#v}"

if [ ! -f "$REGISTRY" ]; then
  echo "[FAIL] Registry file not found: prompts.index.json"
  exit 1
fi
REGISTRY_VERSION=$(grep '"prompt_os_version"' "$REGISTRY" | sed 's/.*: *"\([^"]*\)".*/\1/')
REGISTRY_NUMERIC="${REGISTRY_VERSION#v}"

# Collect all prompt YAML versions
PROMPT_FILES=$(find "$PROMPTS_DIR" -name '*.md' -type f | sort)
if [ -z "$PROMPT_FILES" ]; then
  echo "[FAIL] No prompt files found in prompts/"
  exit 1
fi

PROMPT_VERSIONS=()
PROMPT_PATHS=()
for pfile in $PROMPT_FILES; do
  rel_path="${pfile#"$REPO_ROOT/"}"
  yaml_ver=$(awk '/^---$/{n++; next} n==1 && /^version:/{gsub(/^version: */, ""); gsub(/ *$/, ""); print}' "$pfile")
  if [ -z "$yaml_ver" ]; then
    echo "[FAIL] $rel_path — no version field in YAML header"
    exit 1
  fi
  PROMPT_VERSIONS+=("$yaml_ver")
  PROMPT_PATHS+=("$rel_path")
done

echo "--- Source Versions ---"
echo "  Policy (required_promptos_version): $POLICY_VERSION"
echo "  Registry (prompt_os_version):       $REGISTRY_VERSION"
for i in "${!PROMPT_PATHS[@]}"; do
  echo "  ${PROMPT_PATHS[$i]}: ${PROMPT_VERSIONS[$i]}"
done
echo ""

# --- C. Check all file versions are identical ---

ALL_NUMERIC=("$POLICY_NUMERIC" "$REGISTRY_NUMERIC" "${PROMPT_VERSIONS[@]}")
FIRST="${ALL_NUMERIC[0]}"
for ver in "${ALL_NUMERIC[@]}"; do
  if [ "$ver" != "$FIRST" ]; then
    echo "[FAIL] Version strings are not consistent across files."
    echo "       Found $ver but expected $FIRST (matching first source)."
    echo ""
    echo "  Policy:   $POLICY_NUMERIC"
    echo "  Registry: $REGISTRY_NUMERIC"
    for i in "${!PROMPT_PATHS[@]}"; do
      echo "  ${PROMPT_PATHS[$i]}: ${PROMPT_VERSIONS[$i]}"
    done
    exit 1
  fi
done

FILE_VERSION="$FIRST"

# --- D. Determine state ---

echo "--- Validation ---"

if [ "$FILE_VERSION" = "$TAG_NUMERIC" ]; then
  # STATE A: Normal — versions match current tag
  echo "[STATE A] Normal mode — all versions match git tag"
  echo ""
  echo "  File version: $FILE_VERSION"
  echo "  Git tag:      $TAG_NUMERIC"
  echo ""
  for i in "${!PROMPT_PATHS[@]}"; do
    echo "[PASS] ${PROMPT_PATHS[$i]} — version ${PROMPT_VERSIONS[$i]}"
  done
  echo "[PASS] Policy — $POLICY_VERSION"
  echo "[PASS] Registry — $REGISTRY_VERSION"
  echo ""
  echo "=== Version Consistency Summary ==="
  echo "[PASS] All version strings consistent with $LATEST_TAG"
  exit 0

elif [ "$FILE_VERSION" = "$NEXT_PATCH" ]; then
  # STATE B: Release PR — versions are exactly +1 patch ahead
  echo "[STATE B] Release PR mode — versions are next patch ($NEXT_PATCH)"
  echo ""
  echo "  File version:     $FILE_VERSION"
  echo "  Current git tag:  $TAG_NUMERIC"
  echo "  Expected next:    $NEXT_PATCH"
  echo ""
  for i in "${!PROMPT_PATHS[@]}"; do
    echo "[PASS] ${PROMPT_PATHS[$i]} — version ${PROMPT_VERSIONS[$i]} (release)"
  done
  echo "[PASS] Policy — $POLICY_VERSION (release)"
  echo "[PASS] Registry — $REGISTRY_VERSION (release)"
  echo ""
  echo "=== Version Consistency Summary ==="
  echo "[PASS] Release PR validated — all versions consistently at $NEXT_PATCH (next patch after $LATEST_TAG)"
  exit 0

else
  # Neither state — reject
  echo "[FAIL] Version strings do not match any valid state."
  echo ""
  echo "  File version:          $FILE_VERSION"
  echo "  Current git tag:       $TAG_NUMERIC"
  echo "  Allowed (normal):      $TAG_NUMERIC"
  echo "  Allowed (release PR):  $NEXT_PATCH"
  echo ""
  echo "  Only +1 patch increment is allowed for release PRs."
  echo "  Minor or major jumps require tagging first."
  echo ""
  echo "=== Version Consistency Summary ==="
  echo "[FAIL] Version mismatch — not a valid normal or release state."
  exit 1
fi
