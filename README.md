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

## License

MIT — see [LICENSE](LICENSE).
