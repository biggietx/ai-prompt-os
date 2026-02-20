# ADR-005: Prompt Artifact Enforcement

## Status

Accepted

## Date

2026-02-20

## Context

PromptOS v0.4.0 introduced session recording and an export mechanism that allows prompt session artifacts (`prompt_session.json`) to be attached to Orchestrator governed runs. However, attachment was voluntary. A developer could complete an Orchestrator run, pass all verification gates, and merge code without any record of whether PromptOS governed the AI interaction that produced it.

This creates a governance gap. The Orchestrator can prove that code was reviewed, tested, and verified. But it cannot prove that the AI session producing the code was itself governed — that the right prompts were used, in the right version, with the right constraints. Without enforcement, the session artifact is documentation, not governance. It exists when someone remembers to create it, and is absent when they don't. The absence is invisible.

This is not a theoretical risk. In practice, the most common governance failure is not violation but omission. Developers don't intentionally bypass governance — they forget, or they skip steps under time pressure. A system that depends on voluntary compliance degrades silently. By the time the gap is noticed, the audit trail is already incomplete.

## Decision

### Mandatory Artifact Validation

We introduce a validation script (`scripts/validate_prompt_artifact.sh`) that checks for the existence and structural validity of `prompt_session.json` in a specified artifacts directory. The script is designed to be invoked at approval boundaries — specifically at Orchestrator Gate 06 (Verification) or as a CI pipeline step.

The validation performs three levels of checking:

1. **Existence**: The file `prompt_session.json` must be present in the artifacts directory. If it is not, the script fails immediately with a clear message: "Governance requires a PromptOS session artifact." This is the most important check. A missing artifact means the governance chain is broken — there is no record of which prompts governed the work.

2. **Structural validity**: The file must be valid JSON containing all required fields: `timestamp_utc`, `prompt_os_version`, `prompts_used`, `developer`, `target_repo`, and `lint_passed`. These fields are the minimum metadata needed to answer the governance question: "What prompts, at what version, by whom?"

3. **Type correctness**: Key fields are type-checked — `prompts_used` must be an array, `lint_passed` must be a boolean, `timestamp_utc` must match ISO-8601 UTC format. This prevents malformed artifacts from passing validation simply because they contain the right field names with wrong values.

The script uses `jq` for JSON parsing and validation. This is an intentional dependency choice: `jq` is widely available, purpose-built for JSON operations, and avoids the fragility of grep-based JSON parsing. For environments where `jq` is not available, the script fails explicitly rather than silently downgrading validation.

### Integration with Gate 06 Verification

The enforcement script is designed to slot into the Orchestrator's Gate 06 (Verification) as an additional check alongside test results, coverage reports, and other verification evidence. An enforcement gate snippet (`integration/ENFORCEMENT_GATE_SNIPPET.md`) provides the exact bash code needed to add this check.

The integration point is deliberate. Gate 06 is where the Orchestrator determines whether work meets quality and governance standards before approval. By placing prompt artifact validation here, we ensure that:

- No work is approved without a record of prompt governance.
- The check runs after implementation and testing, when the session artifact should already exist.
- Failure at Gate 06 blocks approval — the work cannot proceed until the artifact is provided.

This is enforcement at the approval boundary, not at the development boundary. We do not prevent developers from working without PromptOS — that would be overly restrictive and would break workflows where AI assistance is not used. Instead, we require that when AI assistance is used and the work enters the governed pipeline, the prompt session must be documented.

### CI Check Integration

The CI check script (`scripts/ci_check.sh`) is extended with an optional Step 4 that runs artifact validation when the `PROMPTOS_ARTIFACTS_DIR` environment variable is set. This allows CI pipelines to enforce prompt governance as part of their standard checks without modifying the base script.

The opt-in via environment variable is intentional. Local development runs of `ci_check.sh` (where no artifacts directory exists) should not fail. CI pipelines that enforce governance set the variable; those that don't, skip the check with an informational message. This prevents the enforcement from becoming a nuisance in contexts where it doesn't apply, while remaining mandatory in contexts where it does.

### Separation of Duties Alignment

Prompt artifact enforcement strengthens separation of duties in two ways:

First, it makes the separation observable. A `prompt_session.json` that lists `P05, P06, P07` demonstrates that implementation, verification, and review were performed as distinct steps. Without the artifact, a reviewer must trust the developer's claim that they followed the prompt chain. With it, the claim is backed by a structured, timestamped record.

Second, it prevents the most common separation-of-duties violation: skipping verification and review. A developer who runs only P05 (implementation) and skips P06 and P07 will produce a session artifact that lists only P05. A reviewer inspecting the artifact can immediately see the gap. The artifact doesn't enforce which prompts are used — that remains a team policy decision — but it makes the choice visible and auditable.

### Preventing Silent AI Drift

AI drift occurs when the governance around AI-assisted work loosens over time without anyone noticing. It starts with skipping one prompt "because this task is simple," continues with forgetting to record sessions "because it's just a quick fix," and ends with a codebase where AI-generated work has no governance trail at all.

Enforcement prevents drift by making the absence of governance visible at a hard boundary. When Gate 06 rejects a run because `prompt_session.json` is missing, the developer is forced to either record a session or explicitly justify the absence. The enforcement mechanism transforms governance from a practice (which can be forgotten) into a gate (which must be passed).

This is the difference between a governance policy and a governance system. A policy says "you should record your prompt sessions." A system says "this run will not be approved until you do."

## Consequences

- **Positive**: Prompt governance becomes enforceable at the Orchestrator's approval boundary, closing the audit gap.
- **Positive**: Artifact validation catches both missing and malformed session records before approval.
- **Positive**: CI integration via environment variable allows enforcement to be adopted incrementally across pipelines.
- **Positive**: Separation of duties becomes observable through session artifact inspection.
- **Positive**: Silent governance drift is prevented by requiring artifacts at hard gate boundaries.
- **Negative**: Adds `jq` as a dependency for artifact validation. Mitigation: `jq` is widely available and the script fails explicitly if it is absent.
- **Negative**: Enforcement at Gate 06 does not prevent ungoverned AI work from being done — only from being approved. Mitigation: this is intentional; enforcement at the development boundary would be too restrictive.
- **Negative**: The validation script checks structural validity but cannot verify that the session was authentically conducted (a developer could fabricate a session JSON). Mitigation: session logs are corroborated by git history, PR descriptions, and Orchestrator run records; fabrication would require falsifying multiple artifacts.
