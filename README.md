# AI Prompt OS

A governed prompt repository for AI-assisted software development. Prompts are treated as versioned, reviewable artifacts — not disposable chat messages.

Maintained by [ServiceMark.ai](https://servicemark.ai) for personal use.

## What This Is

A structured set of prompts that enforce discipline in AI-assisted development workflows. Each prompt maps to a gate in a linear process: lock context, declare scope, design, implement, verify, review, and escalate when uncertain.

The prompts are vendor-neutral — they work with Claude, GPT, Gemini, or any capable LLM.

## 60-Second Usage

Run the prompts in order. Each gate must pass before proceeding to the next.

| Order | Prompt | Purpose |
|-------|--------|---------|
| 1 | **P00 — Context Lock** | Fix the project context, stack, and constraints |
| 2 | **P01 — Scope Declaration** | Define what will (and won't) be done |
| 3 | **P03 — Design Gate** | Propose a design before writing code |
| 4 | **P05 — Constrained Builder** | Implement strictly within approved scope and design |
| 5 | **P06 — Verify Forensics** | Audit implementation against scope and design |
| 6 | **P07 — Adversarial Review** | Attack the implementation to find weaknesses |
| 7 | **P08 — Governance Escalation** | Escalate when any gate encounters uncertainty |

**P08** can be triggered from any gate — it is the system's safety valve.

## Core Principle

**Prompts are governed artifacts.**

They are versioned, reviewed, and changed through the same discipline applied to production code. A prompt that shapes AI output is as consequential as the code it produces.

## Versioning

This repository follows [Semantic Versioning](https://semver.org/):

- **Major**: Breaking changes to prompt structure or gate numbering.
- **Minor**: New prompts, new gates, or significant prompt revisions.
- **Patch**: Clarifications, typo fixes, and minor wording improvements.

## Contribution Rules

1. All changes come through **pull requests** — no direct commits to main.
2. Changes to prompt structure or meaning require an **ADR** (Architecture Decision Record) in `adr/`.
3. Every change requires a **CHANGELOG** entry.
4. Prompts must remain **vendor-neutral** — no platform-specific syntax in core prompts.
5. No secrets, credentials, or absolute paths in any file.

## Orchestrator Integration

PromptOS is the instruction layer for the ServiceMark.ai AI Orchestrator Constitution pipeline. Session artifacts (`prompt_session.json`) attach to governed runs as evidence.

**Quick start:**

```bash
# Run a governed session
./bin/promptos dev \
  --prompts "P00,P01,P03,P05,P06,P07" \
  --developer "your-name" \
  --target-repo "your-repo" \
  --notes "session description"

# Export session artifact to orchestrator evidence directory
./session/export_session_artifact.sh \
  --artifacts-dir "./artifacts/evidence/"
```

See [integration/AI_ORCHESTRATOR_INTEGRATION.md](integration/AI_ORCHESTRATOR_INTEGRATION.md) for the full integration contract.

## Repo Contract

Prompts in this repository are **governed artifacts**. They follow the same discipline as production code:

1. Every prompt edit requires a **CHANGELOG** entry.
2. Structural or semantic changes require an **ADR** in `adr/`.
3. All changes come through **pull requests** — no direct commits to main.
4. PRs must reference the **prompt-os version tag** used (e.g., `v0.2.0`).
5. No secrets, credentials, or absolute paths in any file.

A semantic change is any modification that alters the meaning, structure, or governance behavior of the prompt system — adding/removing gates, changing required metadata keys, altering escalation rules, or modifying versioning policy. Wording clarifications and typo fixes do not require an ADR.

## Automation

Run the prompt linter to validate all prompt files:

```bash
./scripts/lint_prompts.sh
```

The linter checks:
- YAML header presence and required keys
- No secret patterns (`sk-`, `gho_`, `apikey=`, `password=`, `token=`)
- No absolute paths (`/Users/`, `C:\Users\`)

It exits with code 1 on any failure, making it suitable for pre-commit hooks or CI.

## Version Pinning

When opening a pull request that used AI-assisted development with this prompt set, state the prompt-os version in your PR description:

> Built using prompt-os **v0.2.0**, prompts: P00, P01, P03, P05, P06, P07

This ensures reviewers know which prompt versions governed the work.

## License

MIT — see [LICENSE](LICENSE).
