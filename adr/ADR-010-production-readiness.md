# ADR-010: Production Readiness

## Status

Accepted

## Date

2026-02-23

## Context

PromptOS v0.9.0 introduced GitHub Actions CI, PR templates, and CODEOWNERS — bringing governance enforcement to the platform level. However, these mechanisms operate in an advisory capacity without branch protection. A developer with push access can still bypass every governance control by pushing directly to `main`. CI runs but does not block. PR templates guide but do not require. CODEOWNERS suggests reviewers but does not mandate them.

This is the difference between governance capability and governance enforcement. Every previous version of PromptOS added capability: lint scripts, session recording, hash verification, chain binding, policy enforcement, CI workflows. Each capability works correctly when used. None of them prevent being bypassed.

Production-grade governance requires that the bypass path does not exist. The only way to merge code into `main` must be through a pull request that passes all required checks and receives required reviews. This is not a policy preference — it is a structural requirement. A governance system with a bypass path is not a governance system; it is a suggestion with tooling.

ServiceMark.ai positions AI governance as a differentiator. For that positioning to hold under scrutiny — from clients, auditors, or enterprise procurement — the governance must be demonstrably enforced, not merely available. "We have governance scripts" is weaker than "our main branch physically cannot accept unreviewed, unvalidated changes."

## Decision

### Branch Protection as Governance Foundation

We enable branch protection on `main` with the following rules:

1. **Require pull request before merging**: No direct pushes to `main`. Every change must go through a PR, ensuring it passes through the template, CI, and review process.

2. **Require at least one approving review**: No self-merging without review. Even for a solo developer, this creates a deliberate checkpoint — the developer must consciously approve their own PR through the GitHub UI rather than pushing directly. For teams, this enforces separation of duties: the author is not the approver.

3. **Require status checks to pass**: Both `PromptOS CI` (lint + registry validation) and `Objective Compliance Check` (PR title and body validation) must pass before merge is allowed. A PR with failing checks cannot be merged, regardless of review status.

4. **Enforce for administrators**: Admin users are not exempt from protection rules. This prevents the common failure mode where governance applies to "everyone else" but not to the person with the most access. Governance that exempts administrators is governance theater.

5. **Block force pushes**: Force pushing to `main` is prohibited. This prevents history rewriting, which would break audit trails, invalidate commit references in STRATEGY.md and daily logs, and undermine the traceability that the entire system depends on.

6. **Block branch deletion**: The `main` branch cannot be deleted. This is a safety net against catastrophic operations.

### Why Governance Without Branch Protection Is Insufficient

Consider the governance chain that PromptOS has built across nine versions:

- Prompts are structured with YAML headers and required metadata (v0.1.0).
- A lint script validates prompt structure (v0.2.0).
- Sessions are recorded as JSON artifacts (v0.3.0).
- A CLI wrapper enforces the session workflow (v0.4.0).
- Artifacts are validated at gate boundaries (v0.5.0).
- Hash sidecars make artifacts tamper-detectable (v0.6.0).
- Policy enforcement rejects wrong versions (v0.7.0).
- Chain hashes bind artifacts to run records (v0.8.0).
- CI validates on every PR (v0.9.0).

Every link in this chain is strong. But the chain is only as strong as the path it guards. If `main` accepts direct pushes, a developer can skip the entire chain — no PR, no CI, no review, no template, no session recording. One `git push origin main` and the governance is irrelevant.

Branch protection closes this path. After v1.0.0, the only way to change `main` is: open PR → fill template → pass CI → pass objective check → get review → merge. Every step in the governance chain is now mandatory, not optional.

### Why CI Must Block Merge

CI that reports results without blocking merge is monitoring, not enforcement. Monitoring is valuable — it tells you what happened. Enforcement is essential — it controls what can happen.

When CI is a required status check, a failing lint or a missing registry entry prevents merge. The developer must fix the issue before proceeding. This is fundamentally different from a CI check that fails after merge — by then, the non-compliant change is already in `main`, and the fix requires another commit, another review, another CI run. Prevention is cheaper than remediation.

Required status checks also prevent the "I'll fix it later" pattern, where a developer merges with known failures intending to address them in a follow-up. In governed systems, "later" often means "never." Required checks eliminate the choice.

### Why Objective Discipline Is Mandatory in Multi-Agent Systems

PromptOS is designed for environments where multiple AI agents and developers work in parallel. In such environments, the coordination challenge is not technical — it is informational. Who is working on what? What changed and why? How does this change relate to the strategic objective it serves?

The objective compliance check (INFRA-V1-003) requires every PR to carry an objective ID in its title and a structured reporting block in its body. Combined with branch protection, this means:

- Every change to `main` is traceable to a strategic objective.
- Every PR contains a standardized summary, test plan, and risk assessment.
- Every PR references the daily log and strategy file.

For a human orchestrator managing 10+ agents, this is the difference between legibility and chaos. Without objective discipline, the orchestrator must read every diff to understand what happened. With it, they can scan PR titles, read structured summaries, and trace changes to objectives — at scale.

### Production-Grade AI Governance for Enterprise Differentiation

The combination of artifact-level governance (prompts, sessions, hashes, chains) and platform-level enforcement (CI, branch protection, required reviews, objective compliance) creates a governance posture that is:

**Demonstrable**: Every governance control is visible in the repository. Branch protection rules are inspectable. CI workflows are readable. PR history shows compliance. An auditor can verify the entire system by examining the repository structure and GitHub settings.

**Enforceable**: No path exists to bypass governance. Direct pushes are blocked. CI must pass. Reviews are required. Objective IDs are validated. This is not "we follow a process" — it is "the system prevents non-compliance."

**Auditable**: The chain from strategic objective → PR → CI check → session artifact → hash verification → run record is complete and unbroken. Every link is recorded, timestamped, and verifiable.

**Scalable**: The system works identically for 1 developer or 100, for 1 agent or 10. Adding capacity does not weaken governance — every new participant goes through the same enforced pipeline.

This positions ServiceMark.ai to make a specific, verifiable claim: "Every AI-assisted change in our repositories is governed by structured prompts, validated by CI, verified by hash integrity, and traceable to a strategic objective. The enforcement is structural, not procedural."

That claim is stronger than any governance policy document because it is backed by infrastructure that makes non-compliance impossible rather than merely discouraged.

## Consequences

- **Positive**: Branch protection eliminates the bypass path, making governance enforcement structural rather than voluntary.
- **Positive**: Required status checks ensure CI validation is mandatory, not advisory.
- **Positive**: Required reviews enforce separation of duties even for solo developers.
- **Positive**: Force push and deletion protection preserves audit trail integrity.
- **Positive**: ServiceMark can demonstrate verifiable, enforceable AI governance to enterprise clients.
- **Negative**: Branch protection adds friction to every change (must open PR, wait for CI, get review). Mitigation: this friction is the governance — it exists to prevent unreviewed changes, and the CI checks complete in under 60 seconds.
- **Negative**: Solo developers must self-review PRs, which reduces the effectiveness of the review requirement. Mitigation: the PR process still enforces CI checks, template completion, and objective tracking; as the team grows, review becomes genuinely independent.
- **Negative**: Emergency hotfixes require the same PR process. Mitigation: the process is fast (~2 minutes for a simple PR with CI); true emergencies can temporarily disable branch protection via GitHub settings with an ADR documenting the exception.
