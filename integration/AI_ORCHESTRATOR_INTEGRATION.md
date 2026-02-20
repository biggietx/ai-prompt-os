# AI Orchestrator Integration

This document defines how PromptOS integrates with the ServiceMark.ai AI Orchestrator Constitution pipeline.

## Overview

The AI Orchestrator Constitution is a gate-ordered, artifact-driven pipeline that governs how AI-generated work moves from plan to production. It produces structured artifacts at each gate:

| Orchestrator Phase | Artifact |
|-------------------|----------|
| Job Definition | `job.json` |
| Planning | `plan.md` |
| Implementation | `patch/` |
| Review | `review.md` |
| Verification | `evidence/` |
| Run Record | `run_record.json` |

**PromptOS is the human/AI instruction layer that feeds the Orchestrator.** It governs the AI session that produces the raw work product — before that product enters the Orchestrator's artifact pipeline.

## Gate Alignment

PromptOS gates map directly to the Orchestrator's lifecycle:

| PromptOS Gate | Orchestrator Phase | Role |
|--------------|-------------------|------|
| P00 — Context Lock | Pre-job | Fixes project context before any work begins |
| P01 — Scope Declaration | Job Definition | Declares what will be built, with boundaries |
| P03 — Design Gate | Planning | Forces design review before implementation |
| P05 — Constrained Builder | Implementation | Produces code within approved scope and design |
| P06 — Verify Forensics | Verification | Audits implementation against design |
| P07 — Adversarial Review | Review | Attacks implementation to surface weaknesses |
| P08 — Governance Escalation | Any phase | Safety valve for uncertainty or violations |

## Separation of Duties

PromptOS enforces four distinct roles across the gate chain:

1. **Writer** (P05 — Constrained Builder): Produces implementation code.
2. **Verifier** (P06 — Verify Forensics): Audits code against scope and design. Independent of the writer.
3. **Reviewer** (P07 — Adversarial Review): Attacks the implementation to find weaknesses. Independent of both writer and verifier.
4. **Integrator** (Human): Approves gate outputs, resolves escalations (P08), and decides what proceeds to the Orchestrator pipeline.

The Orchestrator pipeline continues this separation downstream — the person who merges a patch is not the person who wrote it, and verification evidence is produced independently of implementation.

## Attaching `prompt_session.json` to Governed Runs

When a governed AI session produces work that enters the Orchestrator pipeline, the session artifact must be attached to the run's evidence directory.

### Workflow

1. Run a governed session:

```bash
./bin/promptos dev \
  --prompts "P00,P01,P03,P05,P06,P07" \
  --developer "your-name" \
  --target-repo "your-repo" \
  --notes "Description of the work"
```

2. Export the session artifact into the Orchestrator's artifacts directory:

```bash
./session/export_session_artifact.sh \
  --artifacts-dir "./artifacts/evidence/"
```

3. This copies the session JSON as `prompt_session.json` into the evidence directory:

```
artifacts/
  evidence/
    prompt_session.json    <-- PromptOS session log
    test_results.json      <-- other verification evidence
  run_record.json
```

4. The Orchestrator's run record can now reference the prompt session as part of its governed evidence chain.

### Specifying a Session File

By default, the export script uses the most recent session log. To export a specific session:

```bash
./session/export_session_artifact.sh \
  --artifacts-dir "./artifacts/evidence/" \
  --session-file "./session/logs/session-20260220-031303.json"
```

## PR Requirements

Pull requests for work governed by PromptOS must include:

1. **PromptOS version** — the git tag (e.g., `v0.4.0`)
2. **Prompt IDs used** — which gates were invoked (e.g., `P00, P01, P03, P05, P06, P07`)
3. **Session artifact path** — location of the session JSON in the artifacts directory

Example PR description block:

> **Governed Session**
> - PromptOS Version: `v0.4.0`
> - Prompts Used: `P00, P01, P03, P05, P06, P07`
> - Session Artifact: `artifacts/evidence/prompt_session.json`
> - Developer: `ethan`
> - Target Repo: `TrackVaultApp`

The `./bin/promptos dev` command generates this block automatically.

## Drift Prevention

This integration reduces drift through three mechanisms:

1. **Version pinning**: Every session records the exact PromptOS version. Two developers using the same tag execute identical prompt versions.
2. **Lint enforcement**: Pre-commit hooks and CI checks prevent prompt files from degrading.
3. **Artifact traceability**: The session JSON creates a permanent, machine-readable link between the AI interaction and the Orchestrator run that consumed its output.

## Auditability

At any point, an auditor can:

1. Find a production artifact (e.g., a deployed feature).
2. Trace it to an Orchestrator run record.
3. Find the `prompt_session.json` in the run's evidence.
4. See exactly which prompts governed the AI session, at what version, by which developer.
5. Cross-reference the prompt versions against the PromptOS repository to read the exact instructions the AI received.

This closes the governance loop: from instruction to artifact to production, every step is recorded.
