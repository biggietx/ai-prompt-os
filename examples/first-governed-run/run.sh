#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ARTIFACTS_DIR="$SCRIPT_DIR/artifacts"

echo "=== CORE-EXP-001: First Governed Run ==="
echo ""

# Ensure bin/promptos is executable
if [ ! -x "$REPO_ROOT/bin/promptos" ]; then
  chmod +x "$REPO_ROOT/bin/promptos"
fi

# Create artifacts directory
mkdir -p "$ARTIFACTS_DIR"

# Step 1: Run governed session
echo "--- Step 1: Governed Session ---"
"$REPO_ROOT/bin/promptos" dev \
  --prompts "P00,P01,P03,P05" \
  --developer "ethan" \
  --target-repo "ai-prompt-os" \
  --notes "CORE-EXP-001 first governed run"
echo ""

# Step 2: Export session artifact
echo "--- Step 2: Export Artifact ---"
"$REPO_ROOT/session/export_session_artifact.sh" \
  --artifacts-dir "$ARTIFACTS_DIR"
echo ""

# Step 3: Validate artifact
echo "--- Step 3: Validate Artifact ---"
"$REPO_ROOT/scripts/validate_prompt_artifact.sh" \
  --artifacts-dir "$ARTIFACTS_DIR"
echo ""

# Step 4: Drift lock check
echo "--- Step 4: Drift Lock Check ---"
"$REPO_ROOT/integration/drift_lock_check.sh" \
  --artifact-dir "$ARTIFACTS_DIR"
echo ""

# Final result
echo ""
echo "[PASS] first governed run complete"
echo "Artifact dir: $ARTIFACTS_DIR"
