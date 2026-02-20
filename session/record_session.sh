#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOGS_DIR="$REPO_ROOT/session/logs"
LINT_SCRIPT="$REPO_ROOT/scripts/lint_prompts.sh"

# Defaults
PROMPTS=""
DEVELOPER=""
TARGET_REPO=""
NOTES=""

usage() {
  echo "Usage: $0 --prompts \"P00,P01,...\" --developer \"name\" --target-repo \"repo\" [--notes \"text\"]"
  exit 1
}

# Parse arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --prompts)
      PROMPTS="$2"
      shift 2
      ;;
    --developer)
      DEVELOPER="$2"
      shift 2
      ;;
    --target-repo)
      TARGET_REPO="$2"
      shift 2
      ;;
    --notes)
      NOTES="$2"
      shift 2
      ;;
    *)
      echo "[FAIL] Unknown argument: $1"
      usage
      ;;
  esac
done

# Validate required arguments
if [ -z "$PROMPTS" ] || [ -z "$DEVELOPER" ] || [ -z "$TARGET_REPO" ]; then
  echo "[FAIL] Missing required arguments."
  usage
fi

# Auto-detect prompt-os version from latest git tag
PROMPT_OS_VERSION=$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null || echo "unknown")

# Generate UTC timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID=$(date -u +"%Y%m%d-%H%M%S")

echo "=== Prompt OS Session Recorder ==="
echo "Version: $PROMPT_OS_VERSION"
echo "Session: $SESSION_ID"
echo ""

# Run lint before recording
echo "Running lint..."
LINT_PASSED=false
if "$LINT_SCRIPT" > /dev/null 2>&1; then
  LINT_PASSED=true
  echo "[PASS] Lint passed"
else
  echo "[FAIL] Lint failed — session not recorded."
  exit 1
fi

# Build JSON array of prompts used
PROMPTS_JSON="["
FIRST=true
IFS=',' read -r -a PROMPT_ARRAY <<< "$PROMPTS"
for p in "${PROMPT_ARRAY[@]}"; do
  p=$(echo "$p" | tr -d ' ')
  if [ "$FIRST" = true ]; then
    PROMPTS_JSON="${PROMPTS_JSON}\"${p}\""
    FIRST=false
  else
    PROMPTS_JSON="${PROMPTS_JSON}, \"${p}\""
  fi
done
PROMPTS_JSON="${PROMPTS_JSON}]"

# Ensure logs directory exists with gitignore
mkdir -p "$LOGS_DIR"
GITIGNORE="$LOGS_DIR/.gitignore"
if [ ! -f "$GITIGNORE" ]; then
  printf '# Session logs are local — do not commit project-specific session data\n*.json\n!.gitignore\n' > "$GITIGNORE"
fi

# Escape notes for JSON (basic: replace quotes and newlines)
NOTES_ESCAPED=$(echo "$NOTES" | sed 's/\\/\\\\/g; s/"/\\"/g')

# Write base session JSON (without chain fields)
SESSION_FILE="$LOGS_DIR/session-${SESSION_ID}.json"
cat > "$SESSION_FILE" <<EOF
{
  "timestamp_utc": "${TIMESTAMP}",
  "prompt_os_version": "${PROMPT_OS_VERSION}",
  "prompts_used": ${PROMPTS_JSON},
  "developer": "${DEVELOPER}",
  "target_repo": "${TARGET_REPO}",
  "notes": "${NOTES_ESCAPED}",
  "lint_passed": ${LINT_PASSED}
}
EOF

# Normalize base JSON with jq for deterministic hashing
NORMALIZED_BASE=$(jq '.' "$SESSION_FILE")
printf '%s\n' "$NORMALIZED_BASE" > "$SESSION_FILE"

# Compute artifact hash from normalized base content
ARTIFACT_HASH=$(shasum -a 256 "$SESSION_FILE" | cut -d ' ' -f 1)

# Compute chain hash: sha256(artifact_hash + timestamp_utc)
CHAIN_HASH=$(printf '%s' "${ARTIFACT_HASH}${TIMESTAMP}" | shasum -a 256 | cut -d ' ' -f 1)

# Add chain fields using jq to maintain normalized format
FINAL_JSON=$(jq --arg ah "$ARTIFACT_HASH" --arg ch "$CHAIN_HASH" \
  '. + {"artifact_hash": $ah, "chain_hash": $ch}' "$SESSION_FILE")
printf '%s\n' "$FINAL_JSON" > "$SESSION_FILE"

# Generate SHA-256 sidecar from final file
HASH_FILE="${SESSION_FILE%.json}.sha256"
HASH=$(shasum -a 256 "$SESSION_FILE" | cut -d ' ' -f 1)
BASENAME=$(basename "$SESSION_FILE")
echo "$HASH  $BASENAME" > "$HASH_FILE"
echo "[PASS] Hash generated: $HASH_FILE"

echo ""
echo "[PASS] Session recorded: $SESSION_FILE"
echo ""
echo "PR reference:"
echo "  Built using prompt-os ${PROMPT_OS_VERSION}, prompts: ${PROMPTS}"
