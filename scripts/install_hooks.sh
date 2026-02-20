#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$REPO_ROOT/.git-hooks/pre-commit"
TARGET="$REPO_ROOT/.git/hooks/pre-commit"

if [ ! -f "$SOURCE" ]; then
  echo "[FAIL] Hook source not found: .git-hooks/pre-commit"
  exit 1
fi

if [ ! -d "$REPO_ROOT/.git/hooks" ]; then
  mkdir -p "$REPO_ROOT/.git/hooks"
fi

cp "$SOURCE" "$TARGET"
chmod +x "$TARGET"

echo "[PASS] Pre-commit hook installed."
echo "  Source: .git-hooks/pre-commit"
echo "  Target: .git/hooks/pre-commit"
