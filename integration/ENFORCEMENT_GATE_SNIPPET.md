# Enforcement Gate Snippet

Use this snippet to enforce PromptOS governance in your Orchestrator pipeline or CI system.

## Where to Add

Add this check to:

- **Gate 06 (Verification)** in the Orchestrator pipeline
- **CI pipeline** as a required step before merge approval
- **Pre-merge hook** in your repository

## Bash Snippet

```bash
# PromptOS Governance Enforcement
# Blocks approval if prompt_session.json is missing or invalid.
# Add to your verification gate or CI pipeline.

PROMPTOS_DIR="/path/to/ai-prompt-os"
RUN_ARTIFACT_DIR="./artifacts/evidence"

"$PROMPTOS_DIR/scripts/validate_prompt_artifact.sh" \
  --artifacts-dir "$RUN_ARTIFACT_DIR"

# Exit code:
#   0 = prompt_session.json present and valid → proceed
#   1 = missing or invalid → block approval
```

## Example: PASS Output

```
=== PromptOS Artifact Validation ===

Found: ./artifacts/evidence/prompt_session.json
  [PASS] Field present: timestamp_utc
  [PASS] Field present: prompt_os_version
  [PASS] Field present: prompts_used
  [PASS] Field present: developer
  [PASS] Field present: target_repo
  [PASS] Field present: lint_passed
  [PASS] prompts_used is an array
  [PASS] lint_passed is a boolean
  [PASS] timestamp_utc is ISO-8601 UTC format

[PASS] prompt_session.json validated.
```

## Example: FAIL Output (Missing Artifact)

```
=== PromptOS Artifact Validation ===

[FAIL] prompt_session.json not found.
Governance requires a PromptOS session artifact.
  Expected: ./artifacts/evidence/prompt_session.json
```

## Example: FAIL Output (Invalid Schema)

```
=== PromptOS Artifact Validation ===

Found: ./artifacts/evidence/prompt_session.json
  [FAIL] Missing required field: prompt_os_version
  [FAIL] Missing required field: prompts_used
  [PASS] Field present: developer
  [PASS] Field present: target_repo
  [PASS] Field present: lint_passed

[FAIL] prompt_session.json has 2 validation error(s).
```

## Integration with Orchestrator Gate 06

In your Orchestrator's verification gate script:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "--- Gate 06: Verification ---"

# Standard verification checks
./run_tests.sh
./check_coverage.sh

# PromptOS governance enforcement
./path/to/ai-prompt-os/scripts/validate_prompt_artifact.sh \
  --artifacts-dir "$RUN_ARTIFACT_DIR"

echo "[PASS] Gate 06 complete — all checks passed."
```

If `validate_prompt_artifact.sh` exits non-zero, the gate fails and approval is blocked. No governed run can proceed without a valid prompt session artifact.
