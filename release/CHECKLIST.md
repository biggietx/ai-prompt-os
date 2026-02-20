# Release Checklist

Use this checklist before cutting a new PromptOS release.

## Pre-Release

- [ ] All changes committed and pushed to a feature branch.
- [ ] Run prompt lint:
  ```bash
  ./scripts/lint_prompts.sh
  ```
- [ ] Run CI checks:
  ```bash
  ./scripts/ci_check.sh
  ```
- [ ] Run a governed session:
  ```bash
  ./bin/promptos dev \
    --prompts "P00,P01,P03,P05,P06,P07" \
    --developer "your-name" \
    --target-repo "ai-prompt-os" \
    --notes "vX.Y.Z release validation"
  ```
- [ ] Export session artifact:
  ```bash
  ./session/export_session_artifact.sh \
    --artifacts-dir "./artifacts/evidence/"
  ```
- [ ] Validate artifact + hash:
  ```bash
  ./scripts/validate_prompt_artifact.sh \
    --artifacts-dir "./artifacts/evidence/"
  ```
- [ ] Run drift lock check:
  ```bash
  ./integration/drift_lock_check.sh \
    --artifact-dir "./artifacts/evidence/"
  ```

## Version Bump

- [ ] Update all prompt YAML headers: `version: X.Y.Z`
- [ ] Update `prompts.index.json`: version fields + timestamps
- [ ] Update `policy/promptos_policy.json`: `required_promptos_version`
- [ ] Update `CHANGELOG.md`: add new version entry
- [ ] Add ADR if any semantic/structural changes were made

## Release

- [ ] Merge PR to `main`
- [ ] Tag the release:
  ```bash
  git tag vX.Y.Z
  git push origin main
  git push origin vX.Y.Z
  ```
- [ ] Verify CI passes on main
- [ ] Update `STRATEGY.md` and `LOGS/DAILY/` if using orchestrator tracking
