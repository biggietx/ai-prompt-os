#!/usr/bin/env bash
set -euo pipefail

ARTIFACTS_DIR=""
SESSION_FILE=""

usage() {
  echo "Usage: $0 --artifacts-dir <run_artifacts_dir> --session-file <path>"
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --artifacts-dir)
      ARTIFACTS_DIR="$2"
      shift 2
      ;;
    --session-file)
      SESSION_FILE="$2"
      shift 2
      ;;
    *)
      echo "[FAIL] Unknown argument: $1"
      usage
      ;;
  esac
done

if [ -z "$ARTIFACTS_DIR" ] || [ -z "$SESSION_FILE" ]; then
  echo "[FAIL] Both --artifacts-dir and --session-file are required."
  usage
fi

if [ ! -f "$SESSION_FILE" ]; then
  echo "[FAIL] Session file not found: $SESSION_FILE"
  exit 1
fi

PROMPT_DIR="$ARTIFACTS_DIR/prompt"
mkdir -p "$PROMPT_DIR"

# Copy session JSON
cp "$SESSION_FILE" "$PROMPT_DIR/prompt_session.json"
echo "[PASS] Copied: $PROMPT_DIR/prompt_session.json"

# Copy hash file if it exists
HASH_SOURCE="${SESSION_FILE%.json}.sha256"
if [ -f "$HASH_SOURCE" ]; then
  cp "$HASH_SOURCE" "$PROMPT_DIR/prompt_session.sha256"
  echo "[PASS] Copied: $PROMPT_DIR/prompt_session.sha256"
else
  echo "[WARN] No .sha256 hash file found alongside session file."
fi

echo ""
echo "[PASS] Prompt session attached to run artifacts."
echo "  Directory: $PROMPT_DIR"
