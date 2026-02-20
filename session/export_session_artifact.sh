#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOGS_DIR="$REPO_ROOT/session/logs"

ARTIFACTS_DIR=""
SESSION_FILE=""

usage() {
  echo "Usage: $0 --artifacts-dir <path> [--session-file <path>]"
  echo ""
  echo "Options:"
  echo "  --artifacts-dir    Destination directory for the exported artifact (required)"
  echo "  --session-file     Specific session JSON to export (optional; defaults to newest)"
  exit 1
}

# Parse arguments
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

if [ -z "$ARTIFACTS_DIR" ]; then
  echo "[FAIL] --artifacts-dir is required."
  usage
fi

# If no session file specified, find the newest one
if [ -z "$SESSION_FILE" ]; then
  if [ ! -d "$LOGS_DIR" ]; then
    echo "[FAIL] No session logs directory found: session/logs/"
    exit 1
  fi

  # Find newest .json file in logs dir (Bash 3.x compatible)
  NEWEST=""
  NEWEST_TIME=0
  for f in "$LOGS_DIR"/*.json; do
    if [ ! -f "$f" ]; then
      continue
    fi
    # Use stat to get modification time (macOS compatible)
    MOD_TIME=$(stat -f "%m" "$f" 2>/dev/null || stat -c "%Y" "$f" 2>/dev/null || echo "0")
    if [ "$MOD_TIME" -gt "$NEWEST_TIME" ]; then
      NEWEST_TIME=$MOD_TIME
      NEWEST="$f"
    fi
  done

  if [ -z "$NEWEST" ]; then
    echo "[FAIL] No session JSON files found in session/logs/"
    exit 1
  fi

  SESSION_FILE="$NEWEST"
fi

if [ ! -f "$SESSION_FILE" ]; then
  echo "[FAIL] Session file not found: $SESSION_FILE"
  exit 1
fi

# Ensure artifacts directory exists
mkdir -p "$ARTIFACTS_DIR"

# Copy session artifact
DEST="$ARTIFACTS_DIR/prompt_session.json"
cp "$SESSION_FILE" "$DEST"

# Copy hash file if it exists
HASH_SOURCE="${SESSION_FILE%.json}.sha256"
HASH_DEST="$ARTIFACTS_DIR/prompt_session.sha256"
if [ -f "$HASH_SOURCE" ]; then
  cp "$HASH_SOURCE" "$HASH_DEST"
  echo "  Hash:        $HASH_DEST"
fi

echo "[PASS] Session artifact exported."
echo "  Source: $SESSION_FILE"
echo "  Destination: $DEST"
