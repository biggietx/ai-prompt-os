# ADR-007: Orchestrator Policy Enforcement

## Status

Accepted

## Date

2026-02-20

## Context

PromptOS v0.6.0 established cryptographic tamper detection for session artifacts. Artifacts are hashed at creation and verified at validation time. This ensures that what was recorded is what gets validated. However, integrity alone does not ensure compliance. A perfectly intact artifact from an outdated or unauthorized PromptOS version is still a governance failure.

Consider: a team standardizes on PromptOS v0.7.0, which includes critical governance controls — hash verification, policy enforcement, and separation-of-duties prompts. A developer, working from a stale clone, generates a session artifact using v0.5.0, which lacks hash verification entirely. The artifact is structurally valid, passes schema checks, and even has correct field types. But it was produced by a version of PromptOS that did not enforce the governance controls the team now requires. Without version enforcement, this outdated artifact passes validation and enters the Orchestrator pipeline as if it met current standards.

This is version drift — the governance equivalent of running production code against an outdated dependency. The fix is policy-level version enforcement: a declared governance policy that specifies which PromptOS version is acceptable, checked at the validation boundary.

## Decision

### Centralized Governance Policy

We introduce a policy file (`policy/promptos_policy.json`) that declares governance expectations as machine-readable configuration:

```json
{
  "required_promptos_version": "v0.7.0",
  "enforce_hash_validation": true,
  "require_prompts_declared": true
}
```

The policy file serves as the single source of truth for governance requirements. When the team decides to upgrade to a new PromptOS version, they update one file. All validation — CI checks, gate enforcement, artifact validation — reads from this policy. This eliminates the failure mode where different parts of the pipeline enforce different version expectations.

The policy is intentionally minimal. It declares what is required, not how to enforce it. Enforcement logic lives in the validation scripts. This separation means the policy can evolve (adding new requirements) without changing enforcement mechanics, and enforcement can be improved without touching the policy.

### Version Enforcement at Validation Time

The artifact validation script (`scripts/validate_prompt_artifact.sh`) now includes a policy enforcement step after hash verification. It reads `required_promptos_version` from the policy file and compares it to the `prompt_os_version` recorded in the session artifact. If they do not match, validation fails.

This is a hard failure. An artifact from the wrong PromptOS version cannot be validated, cannot pass the verification gate, and cannot enter the Orchestrator pipeline. The error message is explicit:

```
[FAIL] PromptOS version mismatch.
  Required: v0.7.0
  Found:    v0.5.0
```

The developer must regenerate the artifact using the correct PromptOS version. There is no override, no warning-only mode. Version enforcement is binary: match or reject.

This strictness is intentional. Version mismatches are not edge cases to handle gracefully — they are governance violations that must be corrected at the source. A softer approach (warnings, overrides) would undermine the enforcement by allowing exceptions to accumulate until they become the norm.

### Verification Gate Enforcement Wrapper

We introduce a verification gate enforcer (`integration/verification_gate_enforcer.sh`) — a single script that the Orchestrator calls at Gate 06 to validate prompt governance. The enforcer:

1. Locates the prompt artifact in the run's artifacts directory (checking `prompt/` subdirectory first, then root).
2. Delegates to `validate_prompt_artifact.sh` for schema validation, hash verification, and policy enforcement.
3. Returns a clear gate verdict: `[GATE PASS]` or `[GATE BLOCKED]`.

The enforcer is the integration contract between PromptOS and the Orchestrator. The Orchestrator does not need to understand prompt validation internals — it calls one script and gets a pass/fail result. This clean boundary means PromptOS can add new validation checks (new policy fields, additional integrity measures) without requiring Orchestrator changes.

The gate terminology is deliberate. "GATE BLOCKED" signals that this is not a soft failure or a warning — the verification gate cannot proceed. The Orchestrator treats this the same as a failed test suite or a missing code review: the run is blocked until the issue is resolved.

### Run Record Attachment

The attachment helper (`integration/attach_prompt_to_run.sh`) formalizes how prompt artifacts are placed into Orchestrator run artifact directories. It copies both the session JSON and its hash sidecar into a `prompt/` subdirectory within the run's artifacts:

```
run_artifacts/
  prompt/
    prompt_session.json
    prompt_session.sha256
  evidence/
  patches/
  run_record.json
```

The `prompt/` subdirectory keeps prompt artifacts organized alongside other Orchestrator evidence without namespace collisions. The helper validates that source files exist before copying and fails explicitly if they do not.

### Completing the Governance Loop

With policy enforcement, the governance loop is now closed:

1. **Policy declares requirements** → `promptos_policy.json` specifies the required version.
2. **Session records usage** → `record_session.sh` captures which prompts were used, at which version.
3. **Hash proves integrity** → SHA-256 sidecar proves the artifact was not modified after creation.
4. **Validation enforces compliance** → Schema, hash, and policy checks must all pass.
5. **Gate blocks non-compliance** → Verification gate wrapper rejects runs that fail validation.
6. **Attachment preserves evidence** → Session artifact and hash are stored in the run record.

At every step, failure is loud and blocking. There is no path from prompt usage to Orchestrator approval that bypasses governance. A developer who uses the wrong PromptOS version, tampers with an artifact, or skips session recording will be stopped at the verification gate with a clear error message explaining what went wrong.

This is the difference between governance documentation and a governance system. Documentation describes what should happen. A system enforces what must happen.

## Consequences

- **Positive**: Version enforcement prevents outdated PromptOS versions from producing accepted artifacts, eliminating version drift.
- **Positive**: Centralized policy file provides a single source of truth for governance requirements.
- **Positive**: Verification gate wrapper gives the Orchestrator a clean, single-script integration point.
- **Positive**: The governance loop is now closed — from policy declaration through artifact validation to gate enforcement.
- **Negative**: Strict version matching means all team members must upgrade PromptOS simultaneously when the policy changes. Mitigation: coordinate version bumps as team-wide events with clear communication.
- **Negative**: Policy file is a single point of governance configuration — corruption or accidental modification could block all validation. Mitigation: policy file is version-controlled and changes require PRs with review.
- **Negative**: The gate enforcer assumes a file-based artifacts directory structure. Mitigation: the enforcer is a thin wrapper; alternative artifact stores can be supported by replacing or wrapping it.
