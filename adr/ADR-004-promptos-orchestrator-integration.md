# ADR-004: PromptOS Orchestrator Integration

## Status

Accepted

## Date

2026-02-20

## Context

PromptOS v0.3.0 established session recording, lint enforcement, and CI validation. These capabilities make the prompt system internally consistent — prompts are structured, validated, and their usage is logged. However, prompts do not exist in isolation. They are the instruction layer for AI-assisted development sessions whose outputs feed into a broader governance pipeline.

ServiceMark.ai operates an AI Orchestrator Constitution model: a gate-ordered, artifact-driven pipeline that governs how AI-generated work moves from plan to production. The pipeline produces structured artifacts at each gate — job definitions, plans, patches, reviews, verification evidence, and run records. Each artifact is traceable, and the pipeline enforces separation of duties between roles (writer, reviewer, verifier, integrator).

PromptOS sits upstream of this pipeline. It governs the human-AI interaction that produces the raw work product. But without integration, a gap exists: the Orchestrator can verify that a patch was reviewed and tested, but it cannot verify that the AI session producing the patch was itself governed. The prompt session — which prompts were used, in what version, by whom — is invisible to the artifact chain.

This ADR addresses that gap by making prompt session logs a first-class artifact in the Orchestrator pipeline and by introducing a one-command wrapper that reduces human variance in the governed session workflow.

## Decision

### Prompt Sessions as Governed Artifacts

The session recording system introduced in v0.3.0 produces JSON logs capturing prompt usage metadata. In v0.4.0, we formalize these logs as artifacts that can be attached to Orchestrator runs.

A new export script (`session/export_session_artifact.sh`) copies the session JSON into an artifacts directory specified by the caller. This is the integration point: the Orchestrator invokes the export script as part of its evidence-collection phase, and the resulting `prompt_session.json` becomes part of the governed run record alongside patches, review notes, and verification evidence.

This design keeps PromptOS and the Orchestrator loosely coupled. PromptOS does not need to know about the Orchestrator's internal structure. The Orchestrator does not need to parse prompt files. The session JSON is the contract between them — a self-contained artifact that answers: "Which prompts governed this work, at what version, and who ran them?"

The export script defaults to the most recent session log if no specific file is provided. This supports the common workflow where a developer completes a governed session and immediately exports the artifact. For cases where multiple sessions contribute to a single Orchestrator run, the specific session file can be passed explicitly.

### One-Command Wrapper (`bin/promptos`)

The governed session workflow involves multiple steps: lint, validate, record, export. In v0.3.0, each step required invoking a separate script with its own arguments. This creates variance — developers may skip steps, run them in the wrong order, or forget to lint before recording.

The `promptos` CLI wrapper consolidates these steps behind subcommands:

- `promptos version` — deterministic version output from git tags.
- `promptos lint` — delegates to the lint script.
- `promptos ci` — delegates to the CI check script.
- `promptos hooks install` — delegates to the hook installer.
- `promptos dev` — the primary workflow command. It runs lint, validates that requested prompts exist in the registry, records the session, and outputs a PR-ready audit snippet.

The `dev` subcommand is the critical path. By bundling lint-check, registry validation, session recording, and audit output into a single invocation, it eliminates the most common source of human error: forgetting a step. A developer who runs `promptos dev` gets a complete, validated, auditable session record in one command.

The wrapper is deliberately thin. It delegates to existing scripts rather than reimplementing their logic. This means improvements to lint, CI checks, or session recording automatically flow through the wrapper without changes. It is a coordination layer, not an abstraction layer.

### Audit Trail Continuity

The combination of session recording, artifact export, and the wrapper CLI creates an unbroken audit trail from prompt selection to Orchestrator evidence:

1. Developer selects prompts and runs `promptos dev`.
2. Lint validates prompt integrity.
3. Registry confirms prompt existence.
4. Session JSON is recorded with version, prompts, developer, and target repo.
5. Export script copies session JSON into the Orchestrator's artifacts directory.
6. Orchestrator includes `prompt_session.json` in the governed run record.

At any point after the fact, an auditor can trace backward from a production artifact through the Orchestrator run record to the exact prompt session that governed its creation. This is the governance value proposition: not just that prompts were used, but that their usage is provably recorded and attached to the work they governed.

### Determinism

The wrapper enforces determinism by removing discretion from the workflow. Without it, a developer chooses which scripts to run and in what order. With it, the `dev` command defines the exact sequence: lint → validate → record → output. The developer's only decisions are which prompts to declare and what notes to attach — the process itself is fixed.

Version pinning reinforces this. The wrapper reports the exact git tag, and the audit snippet includes it. Two developers using the same tag will execute the same prompt versions in the same validation sequence. Differences in output are attributable to the AI interaction itself, not to variance in the governance process.

## Consequences

- **Positive**: Prompt sessions become traceable artifacts in the Orchestrator pipeline, closing the governance gap between AI interaction and artifact production.
- **Positive**: One-command wrapper eliminates step-skipping and ordering errors in governed sessions.
- **Positive**: Loose coupling via JSON artifact keeps PromptOS and Orchestrator independently evolvable.
- **Positive**: Audit trail extends from prompt selection through to production artifacts.
- **Negative**: Export script assumes a file-based artifacts directory. Non-filesystem artifact stores would need an adapter. Mitigation: the script is simple enough to wrap or replace.
- **Negative**: Wrapper adds a dependency on the `bin/` directory being in PATH or invoked with a relative path. Mitigation: documented in README; teams can alias or symlink as needed.
- **Negative**: Session JSON format is a de facto contract between PromptOS and the Orchestrator. Changes require coordination. Mitigation: schema is versioned; breaking changes require a new ADR.
