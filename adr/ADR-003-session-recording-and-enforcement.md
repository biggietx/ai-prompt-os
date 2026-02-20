# ADR-003: Session Recording and Enforcement

## Status

Accepted

## Date

2026-02-19

## Context

Prompt OS v0.2.0 established a governed prompt structure with a machine-readable registry and lint enforcement. However, two critical gaps remained:

1. **No usage audit trail**: There was no systematic way to record which prompts were used during a development session, by whom, or against which repository. Without this, governance exists in theory but cannot be verified in practice. A team lead asking "were the prompts actually followed?" has no artifact to inspect.

2. **No enforcement at commit boundaries**: The lint script existed but ran only when manually invoked. Nothing prevented a developer from committing prompt files with missing headers, leaked secrets, or broken structure. Governance that depends entirely on voluntary compliance is governance in name only.

These gaps undermine the core premise of Prompt OS: that prompts are governed artifacts deserving the same discipline as production code.

## Decision

### Session Recording

We introduce a CLI-driven session recorder (`session/record_session.sh`) that produces a structured JSON log for each governed development session. The recorder:

- Accepts explicit arguments: which prompts were used, the developer's name, the target repository, and optional notes.
- Auto-detects the prompt-os version from the latest git tag, eliminating manual version tracking.
- Runs the prompt linter before recording. If lint fails, the session is not recorded. This ensures that session logs are only created when the prompt set is in a valid state — a session recorded against broken prompts is worse than no record at all.
- Writes output to `session/logs/` as timestamped JSON files that conform to a declared schema (`schema_prompt_session.json`).

The session log serves multiple purposes. For individual developers, it provides a reference to paste into pull request descriptions — "this work was governed by prompt-os v0.3.0 using P00, P01, P03, P05." For teams, it creates an audit trail that can answer questions about process compliance without requiring trust in self-reporting. For the prompt system itself, it provides usage data that can inform which prompts are valuable and which are being skipped.

Session logs are gitignored by default. They contain project-specific details that belong to the target repository's workflow, not to the prompt-os repository itself. Teams that want centralized logging can adjust this, but the default protects against accidental leakage of project details.

### Pre-Commit Enforcement

We introduce a git pre-commit hook (`.git-hooks/pre-commit`) that runs the prompt linter before every commit. If any prompt file fails validation — missing YAML keys, detected secrets, absolute paths — the commit is blocked.

This shifts enforcement from "run lint when you remember" to "lint runs automatically at every commit boundary." The hook is not auto-installed. A separate installer script (`scripts/install_hooks.sh`) copies the hook into `.git/hooks/`. This is intentional: auto-installing hooks in a cloned repository is a security anti-pattern. Developers must explicitly opt in.

The pre-commit hook enforces the same checks as manual lint — no additional rules, no surprises. A developer who runs `./scripts/lint_prompts.sh` and sees `[PASS]` can be confident the commit will not be blocked.

### CI-Ready Validation

We introduce a CI check script (`scripts/ci_check.sh`) that extends lint with registry validation. It verifies that every prompt listed in `prompts.index.json` corresponds to an actual file, and that the registry JSON is structurally valid. This catches a class of errors that lint alone cannot: a prompt file that exists but is missing from the registry, or a registry entry pointing to a deleted file.

The CI script is designed to run in any CI environment without dependencies beyond Bash and standard Unix tools. It exits non-zero on any failure, making it directly usable as a CI step.

### Alignment with Separation of Duties

Session recording reinforces separation of duties by making prompt usage observable. When a PR states "governed by P00, P01, P03, P05, P06," a reviewer can verify that the verification and review gates were actually invoked — not just the implementation gate. Without session logs, the separation of duties defined in the prompt chain is aspirational rather than auditable.

Pre-commit enforcement reinforces separation of duties by preventing the builder from bypassing structural governance. The person writing code cannot also silently degrade the prompt infrastructure that governs their work.

### Determinism

Both capabilities support determinism by narrowing the space of valid states. Session recording captures the exact prompt-os version and prompt set used, making sessions reproducible. Pre-commit enforcement ensures the prompt set cannot drift into an invalid state between lint runs. Together, they move the system from "prompts should be governed" to "prompts are provably governed."

## Consequences

- **Positive**: Session logs create an audit trail for prompt usage across projects.
- **Positive**: Pre-commit hooks prevent structural drift at the commit boundary.
- **Positive**: CI check script enables automated validation in any pipeline.
- **Positive**: Lint-gating on session recording ensures logs are only created against valid prompt sets.
- **Negative**: Pre-commit hooks add latency to every commit. Mitigation: lint is lightweight and runs in under a second for the current prompt set.
- **Negative**: Session recording requires developer discipline to invoke. Mitigation: the playbook and PR checklist reference it; teams can enforce via PR templates.
- **Negative**: Manual registry maintenance could fall out of sync with prompt files. Mitigation: CI check validates registry-to-file correspondence.
