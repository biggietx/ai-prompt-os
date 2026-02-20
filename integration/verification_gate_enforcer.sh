#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VALIDATE_SCRIPT="$REPO_ROOT/scripts/validate_prompt_artifact.sh"
RUN_ARTIFACTS=""

usage() {
  echo "Usage: $0 --run-artifacts <path>"
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --run-artifacts)
      RUN_ARTIFACTS="$2"
      shift 2
      ;;
    *)
      echo "[FAIL] Unknown argument: $1"
      usage
      ;;
  esac
done

if [ -z "$RUN_ARTIFACTS" ]; then
  echo "[FAIL] --run-artifacts is required."
  usage
fi

# Determine artifact location — check prompt/ subdirectory first, then root
ARTIFACT_DIR="$RUN_ARTIFACTS/prompt"
if [ ! -d "$ARTIFACT_DIR" ]; then
  ARTIFACT_DIR="$RUN_ARTIFACTS"
fi

echo "=== Verification Gate: PromptOS Enforcement ==="
echo ""

if ! "$VALIDATE_SCRIPT" --artifacts-dir "$ARTIFACT_DIR"; then
  echo ""
  echo "[GATE BLOCKED] Verification gate cannot proceed."
  exit 1
fi

echo ""
echo "[GATE PASS] Prompt artifact validated."
exit 0
