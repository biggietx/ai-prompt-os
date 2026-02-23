# Strategic Objectives

> **Owner**: ServiceMark.ai
> **Last updated**: 2026-02-20

---

## INFRA-V1-003 — Objective governance + PR enforcement

**Intent:** Introduce structured objective tracking, daily logs, and PR enforcement to ensure multi-agent clarity and compliance.

**Success Metric:**
- All PRs require Objective ID in title.
- All PRs require mandatory reporting block.
- STRATEGY.md exists and is updated.
- Daily logs exist and are used.

**Status:** Done

**Owner Agent:** Infrastructure-Agent

**Links:** —

**Latest Update (2026-02-23):** PR #1 merged. Objective governance live on main.

---

### Handoff (2026-02-20)

How to run/test:
- Open PR without Objective ID → CI must fail.
- Open PR with valid ID + checklist → CI must pass.

Key decisions:
- Objective ID regex enforces DOMAIN-STAGE-### format.

Known limitations:
- Does not validate daily log contents, only PR structure.

Follow-ups:
- Potential future validation of STRATEGY updates.

---

## INFRA-V1-004 — Production governance hardening + v1.0.0 release

**Intent:** Convert repository from governance-enabled to production-grade governance-enforced. Enable branch protection, merge compliance PRs, cut v1.0.0.

**Success Metric:**
- Branch protection enabled on main.
- Required status checks: PromptOS CI + Objective Compliance Check.
- Required PR reviews before merge.
- v1.0.0 tagged and released.

**Status:** Done

**Owner Agent:** Infrastructure-Agent

**Links:** Tag `v1.0.0`

**Latest Update (2026-02-23):** Production hardening complete. Branch protection enabled. v1.0.0 released.

---

### Handoff (2026-02-23)

How to run/test:
- Direct push to main → blocked by branch protection.
- PR without objective ID → blocked by Objective Compliance Check.
- PR with failing lint → blocked by PromptOS CI.
- Tag push → triggers release workflow.

Key decisions:
- Branch protection enforces for admins (no bypass).
- v1.0.0 marks governance infrastructure complete.

Known limitations:
- Solo developer must self-review PRs.
- Emergency hotfixes still require PR process.

Follow-ups:
- None critical. Potential future: cryptographic signing, multi-session chaining.

---

## OBJ-001: Initial Prompt OS scaffold

- **Intent**: Establish the foundational governed prompt repository with gate-mirrored structure, separation of duties, and vendor-neutral prompts.
- **Success metric**: 7 prompt files (P00–P08), ADR-001, README, CHANGELOG, LICENSE — all committed and tagged.
- **Status**: Done
- **Owner agent**: promptos-sculptor
- **Links**: Tag `v0.1.0`, commit `137fa67`
- **Latest update** (2026-02-19): v0.1.0 shipped. 11 files, 565 insertions. Core gate structure established.

### Handoff (2026-02-19)

- **How to run/test**: Read prompts in order P00→P08. Each is copy/paste-ready.
- **Key decisions**: Gate numbers skip 02/04 intentionally (reserved). Vendor-neutral plain text. SemVer from day one.
- **Known limitations**: No automation, no enforcement — prompts are advisory only.
- **Follow-ups**: Registry, lint, session recording (OBJ-002, OBJ-003).

---

## OBJ-002: Prompt registry + lint enforcement

- **Intent**: Make prompts machine-readable and add lightweight validation to prevent structural drift, secret leakage, and absolute paths.
- **Success metric**: `prompts.index.json` registry, `scripts/lint_prompts.sh` passing all 7 files, team playbook, ADR-002.
- **Status**: Done
- **Owner agent**: promptos-sculptor
- **Links**: Tag `v0.2.0`, commit `43dfb22`
- **Latest update** (2026-02-19): v0.2.0 shipped. Registry + lint + playbook. 13 files changed, 446 insertions.

### Handoff (2026-02-19)

- **How to run/test**: `./scripts/lint_prompts.sh` — must print `[PASS] All checks passed`.
- **Key decisions**: Manual registry maintenance (no auto-generation). Lint checks YAML headers, required keys, secret patterns, absolute paths.
- **Known limitations**: Lint uses pattern matching, not a full YAML parser. Registry must be manually synced.
- **Follow-ups**: Session recording (OBJ-003), pre-commit hooks (OBJ-003).

---

## OBJ-003: Session recording + CI integration

- **Intent**: Create an audit trail for prompt usage and enforce lint at commit boundaries via pre-commit hooks and CI checks.
- **Success metric**: `session/record_session.sh` producing JSON logs, pre-commit hook blocking on lint failure, `scripts/ci_check.sh` passing.
- **Status**: Done
- **Owner agent**: promptos-sculptor
- **Links**: Tag `v0.3.0`, commit `4acfbed`
- **Latest update** (2026-02-19): v0.3.0 shipped. Session recorder, pre-commit hook, CI check, schema, ADR-003. 16 files changed, 408 insertions.

### Handoff (2026-02-19)

- **How to run/test**: `./session/record_session.sh --prompts "P00,P01" --developer "name" --target-repo "repo"`. Install hooks: `./scripts/install_hooks.sh`. CI: `./scripts/ci_check.sh`.
- **Key decisions**: Hooks are opt-in (manual install). Session logs gitignored by default. Lint-gated recording.
- **Known limitations**: Session recording requires developer discipline to invoke.
- **Follow-ups**: CLI wrapper (OBJ-004), artifact export (OBJ-004).

---

## OBJ-004: CLI wrapper + orchestrator integration

- **Intent**: Consolidate governed session workflow into one command and define integration contract with AI Orchestrator Constitution pipeline.
- **Success metric**: `bin/promptos dev` producing audit snippet, `session/export_session_artifact.sh` exporting to artifacts dir, integration contract doc.
- **Status**: Done
- **Owner agent**: promptos-sculptor
- **Links**: Tag `v0.4.0`, commit `24f3ab6`
- **Latest update** (2026-02-20): v0.4.0 shipped. CLI wrapper, export script, integration doc, ADR-004. 14 files changed, 550 insertions.

### Handoff (2026-02-20)

- **How to run/test**: `./bin/promptos dev --prompts "P00,P01,P03,P05" --developer "name" --target-repo "repo"`. Export: `./session/export_session_artifact.sh --artifacts-dir "./artifacts/"`.
- **Key decisions**: Wrapper delegates to existing scripts (coordination layer, not abstraction). Loose coupling via JSON artifact.
- **Known limitations**: Artifact attachment is voluntary. No enforcement at gate boundary.
- **Follow-ups**: Artifact validation (OBJ-005), hash verification (OBJ-006).

---

## OBJ-005: Enforced prompt artifact validation

- **Intent**: Block Orchestrator approval when `prompt_session.json` is missing or structurally invalid. Close the governance gap.
- **Success metric**: `scripts/validate_prompt_artifact.sh` rejecting missing/invalid artifacts with exit 1. CI step 4 integrated.
- **Status**: Done
- **Owner agent**: promptos-sculptor
- **Links**: Tag `v0.5.0`, commit `0215e9e`
- **Latest update** (2026-02-20): v0.5.0 shipped. Validation script, enforcement gate snippet, CI integration, ADR-005. 13 files changed, 337 insertions.

### Handoff (2026-02-20)

- **How to run/test**: `./scripts/validate_prompt_artifact.sh --artifacts-dir "<path>"`. CI with artifacts: `PROMPTOS_ARTIFACTS_DIR=<path> ./scripts/ci_check.sh`.
- **Key decisions**: Uses `jq` for JSON validation. CI step is opt-in via env var. Enforcement at approval boundary, not development boundary.
- **Known limitations**: Depends on `jq`. Does not verify artifact authenticity (only structure).
- **Follow-ups**: Hash verification (OBJ-006), version enforcement (OBJ-007).

---

## OBJ-006: Artifact immutability via SHA-256

- **Intent**: Make session artifacts tamper-detectable with cryptographic hashing. Any modification after creation produces a verifiable mismatch.
- **Success metric**: `.sha256` sidecar generated on recording, hash verified on validation, tampering detected and blocked.
- **Status**: Done
- **Owner agent**: promptos-sculptor
- **Links**: Tag `v0.6.0`, commit `9309bce`
- **Latest update** (2026-02-20): v0.6.0 shipped. Hash generation, hash validation, export copies sidecar, ADR-006. 14 files changed, 167 insertions.

### Handoff (2026-02-20)

- **How to run/test**: Record session → `.sha256` sidecar created automatically. Validate: `./scripts/validate_prompt_artifact.sh --artifacts-dir "<path>"`. Tamper test: modify JSON, re-validate → FAIL.
- **Key decisions**: SHA-256 via `shasum` (no new dependencies). Missing hash file = hard failure. Export copies both files.
- **Known limitations**: Integrity verification, not cryptographic signing. No non-repudiation.
- **Follow-ups**: Policy enforcement (OBJ-007), chain binding (OBJ-008).

---

## OBJ-007: Policy enforcement + verification gate

- **Intent**: Enforce policy-level version control and provide Orchestrator with a single-script verification gate wrapper.
- **Success metric**: Policy file declaring required version, validation rejecting version mismatches, gate enforcer returning PASS/FAIL.
- **Status**: Done
- **Owner agent**: promptos-sculptor
- **Links**: Tag `v0.7.0`, commit `805820b` (included in v0.8.0 commit)
- **Latest update** (2026-02-20): v0.7.0 capabilities shipped. Policy file, version enforcement, gate enforcer, run attachment helper, ADR-007.

### Handoff (2026-02-20)

- **How to run/test**: `./integration/verification_gate_enforcer.sh --run-artifacts "<path>"`. Policy: edit `policy/promptos_policy.json`. Attach: `./integration/attach_prompt_to_run.sh --artifacts-dir "<path>" --session-file "<path>"`.
- **Key decisions**: Strict version matching (no ranges). Policy is single source of truth. Gate enforcer checks `prompt/` subdirectory first.
- **Known limitations**: All team members must upgrade simultaneously when policy version changes.
- **Follow-ups**: Chain binding (OBJ-008).

---

## OBJ-008: Chain binding + drift lock + run-record binding

- **Intent**: Bind prompt artifacts into a deterministic hash chain, enabling replay detection, drift locking, and cryptographic run-record linkage.
- **Success metric**: `artifact_hash` and `chain_hash` embedded in session JSON, chain validated on artifact check, drift lock check passing, run record binding working.
- **Status**: Done
- **Owner agent**: promptos-sculptor
- **Links**: Tag `v0.8.0`, commit `805820b`
- **Latest update** (2026-02-20): v0.8.0 shipped. Chain hashing, chain validation, drift lock check, run-record binding, policy flags, ADR-008. 21 files changed, 659 insertions.

### Handoff (2026-02-20)

- **How to run/test**: Record session → `artifact_hash` + `chain_hash` embedded. Validate: `./scripts/validate_prompt_artifact.sh --artifacts-dir "<path>"`. Drift check: `./integration/drift_lock_check.sh --artifact-dir "<path>"`. Bind: `./integration/bind_to_run_record.sh --run-record "<path>" --prompt-artifact "<path>"`.
- **Key decisions**: Two-phase artifact generation (base → hash → final). jq normalization for deterministic hashing. Chain hash = SHA-256(artifact_hash + timestamp). Run binding is one-way (no unbinding).
- **Known limitations**: Hash computation sensitive to jq formatting. No cryptographic signing (integrity only). Binding is permanent.
- **Follow-ups**: None identified — governance loop is closed.
